//! A managed Tor service lifecycle.
//!
//! [`TorService`] ties the [`crate::TorLauncher`] seam and bootstrap parsing
//! into a small, fail-closed state machine that a platform adapter drives:
//! launch tor, feed it control/log lines until it is bootstrapped, then stop it.
//! It owns no I/O of its own, so it is fully unit-testable with a fake launcher.

use serde::{Deserialize, Serialize};
use std::fmt;

use crate::{parse_bootstrap_progress, BootstrapStatus, TorLaunchPlan, TorLauncher};

/// The observable state of a managed tor process.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "state", rename_all = "kebab-case")]
pub enum TorServiceState {
    /// No tor process is tracked.
    Stopped,
    /// Tor has been launched but has not reported bootstrap progress yet.
    Starting,
    /// Tor is bootstrapping; carries the latest progress point.
    Bootstrapping(BootstrapStatus),
    /// Tor has finished bootstrapping (100%).
    Running,
    /// Tor failed to launch or exited unexpectedly.
    Failed { reason: String },
}

/// Errors returned by [`TorService::start`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TorServiceError {
    /// A tor process is already starting, bootstrapping, or running.
    AlreadyRunning,
    /// The launcher failed to spawn tor.
    Launch(String),
}

impl fmt::Display for TorServiceError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::AlreadyRunning => write!(f, "tor service is already running"),
            Self::Launch(reason) => write!(f, "failed to launch tor: {reason}"),
        }
    }
}

impl std::error::Error for TorServiceError {}

/// A fail-closed lifecycle wrapper around a launched tor process.
#[derive(Debug)]
pub struct TorService<L: TorLauncher> {
    launcher: L,
    state: TorServiceState,
    pid: Option<u32>,
}

impl<L: TorLauncher> TorService<L> {
    /// Create a stopped service bound to a launcher.
    pub fn new(launcher: L) -> Self {
        Self {
            launcher,
            state: TorServiceState::Stopped,
            pid: None,
        }
    }

    /// The current lifecycle state.
    pub fn state(&self) -> &TorServiceState {
        &self.state
    }

    /// The PID of the tracked tor process, if any.
    pub fn pid(&self) -> Option<u32> {
        self.pid
    }

    /// Whether tor has finished bootstrapping.
    pub fn is_running(&self) -> bool {
        matches!(self.state, TorServiceState::Running)
    }

    /// Whether tor is starting, bootstrapping, or running.
    pub fn is_active(&self) -> bool {
        matches!(
            self.state,
            TorServiceState::Starting
                | TorServiceState::Bootstrapping(_)
                | TorServiceState::Running
        )
    }

    /// The latest known bootstrap percentage (`0..=100`).
    pub fn bootstrap_percent(&self) -> u8 {
        match &self.state {
            TorServiceState::Bootstrapping(status) => status.percent,
            TorServiceState::Running => 100,
            _ => 0,
        }
    }

    /// Launch tor and move to [`TorServiceState::Starting`].
    ///
    /// Fail-closed: refuses to start a second process while one is active.
    pub fn start(&mut self, plan: &TorLaunchPlan) -> Result<(), TorServiceError> {
        if self.is_active() {
            return Err(TorServiceError::AlreadyRunning);
        }
        match self.launcher.launch(plan) {
            Ok(pid) => {
                self.pid = Some(pid);
                self.state = TorServiceState::Starting;
                Ok(())
            }
            Err(err) => {
                let reason = err.to_string();
                self.state = TorServiceState::Failed {
                    reason: reason.clone(),
                };
                self.pid = None;
                Err(TorServiceError::Launch(reason))
            }
        }
    }

    /// Feed a control-port event or log line; advances bootstrap state.
    ///
    /// Lines that do not carry bootstrap progress, and lines received while the
    /// service is not active, are ignored.
    pub fn ingest_line(&mut self, line: &str) {
        if !self.is_active() {
            return;
        }
        if let Some(progress) = parse_bootstrap_progress(line) {
            self.state = if progress.is_done() {
                TorServiceState::Running
            } else {
                TorServiceState::Bootstrapping(progress)
            };
        }
    }

    /// Record a failure (process exited, controller lost contact, etc.).
    pub fn mark_failed(&mut self, reason: impl Into<String>) {
        self.state = TorServiceState::Failed {
            reason: reason.into(),
        };
        self.pid = None;
    }

    /// Stop tracking tor and return the PID the caller must terminate, if any.
    pub fn stop(&mut self) -> Option<u32> {
        self.state = TorServiceState::Stopped;
        self.pid.take()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io;

    struct OkLauncher(u32);
    impl TorLauncher for OkLauncher {
        fn launch(&self, _plan: &TorLaunchPlan) -> io::Result<u32> {
            Ok(self.0)
        }
    }

    struct FailLauncher;
    impl TorLauncher for FailLauncher {
        fn launch(&self, _plan: &TorLaunchPlan) -> io::Result<u32> {
            Err(io::Error::new(
                io::ErrorKind::NotFound,
                "tor binary missing",
            ))
        }
    }

    fn plan() -> TorLaunchPlan {
        TorLaunchPlan::new("tor", "torrc", "data")
    }

    #[test]
    fn starts_stopped() {
        let service = TorService::new(OkLauncher(1));
        assert_eq!(service.state(), &TorServiceState::Stopped);
        assert!(!service.is_active());
        assert_eq!(service.pid(), None);
    }

    #[test]
    fn start_then_bootstrap_to_running() {
        let mut service = TorService::new(OkLauncher(4242));
        service.start(&plan()).expect("start");
        assert_eq!(service.state(), &TorServiceState::Starting);
        assert_eq!(service.pid(), Some(4242));

        service.ingest_line("650 STATUS_CLIENT NOTICE BOOTSTRAP PROGRESS=45 TAG=conn");
        assert_eq!(service.bootstrap_percent(), 45);
        assert!(service.is_active());
        assert!(!service.is_running());

        service.ingest_line("[notice] Bootstrapped 100% (done): Done");
        assert!(service.is_running());
        assert_eq!(service.bootstrap_percent(), 100);
    }

    #[test]
    fn refuses_double_start() {
        let mut service = TorService::new(OkLauncher(1));
        service.start(&plan()).expect("start");
        assert_eq!(service.start(&plan()), Err(TorServiceError::AlreadyRunning));
    }

    #[test]
    fn launch_failure_is_fail_closed() {
        let mut service = TorService::new(FailLauncher);
        let result = service.start(&plan());
        assert!(matches!(result, Err(TorServiceError::Launch(_))));
        assert!(matches!(service.state(), TorServiceState::Failed { .. }));
        assert_eq!(service.pid(), None);
    }

    #[test]
    fn ignores_lines_while_stopped() {
        let mut service = TorService::new(OkLauncher(1));
        service.ingest_line("[notice] Bootstrapped 100% (done): Done");
        assert_eq!(service.state(), &TorServiceState::Stopped);
    }

    #[test]
    fn stop_returns_pid_and_resets() {
        let mut service = TorService::new(OkLauncher(99));
        service.start(&plan()).expect("start");
        assert_eq!(service.stop(), Some(99));
        assert_eq!(service.state(), &TorServiceState::Stopped);
        assert_eq!(service.stop(), None);
    }
}
