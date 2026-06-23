//! How TorTunnel launches a bundled `tor` process.
//!
//! [`TorLaunchPlan`] is the pure, testable description of *how* tor should be
//! started (binary, torrc, data directory, owning controller). The actual
//! spawning sits behind the [`TorLauncher`] trait so the orchestration logic can
//! be unit-tested with a fake launcher and the real [`StdTorLauncher`] is the
//! only piece that touches the OS.

use std::path::PathBuf;

/// A fully-resolved plan for starting a `tor` process.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TorLaunchPlan {
    /// Path to the bundled `tor` binary.
    pub tor_binary: PathBuf,
    /// Path to the generated `torrc` file.
    pub torrc_path: PathBuf,
    /// Tor `DataDirectory` (must be private to the user).
    pub data_directory: PathBuf,
    /// PID of the controlling process; when set, tor exits if we die.
    pub owning_controller_pid: Option<u32>,
}

impl TorLaunchPlan {
    /// Create a plan with no owning controller set.
    pub fn new(
        tor_binary: impl Into<PathBuf>,
        torrc_path: impl Into<PathBuf>,
        data_directory: impl Into<PathBuf>,
    ) -> Self {
        Self {
            tor_binary: tor_binary.into(),
            torrc_path: torrc_path.into(),
            data_directory: data_directory.into(),
            owning_controller_pid: None,
        }
    }

    /// Tie the tor process lifetime to the given controller PID.
    pub fn with_owning_controller(mut self, pid: u32) -> Self {
        self.owning_controller_pid = Some(pid);
        self
    }

    /// The argument vector passed to the tor binary.
    pub fn args(&self) -> Vec<String> {
        let mut args = vec![
            "-f".to_string(),
            self.torrc_path.display().to_string(),
            "--DataDirectory".to_string(),
            self.data_directory.display().to_string(),
        ];
        if let Some(pid) = self.owning_controller_pid {
            args.push("--__OwningControllerProcess".to_string());
            args.push(pid.to_string());
        }
        args
    }
}

/// Spawns a tor process from a [`TorLaunchPlan`], returning its PID.
///
/// Implemented by [`StdTorLauncher`] for production and by fakes in tests.
pub trait TorLauncher {
    fn launch(&self, plan: &TorLaunchPlan) -> std::io::Result<u32>;
}

/// The real launcher that spawns tor via [`std::process::Command`].
#[derive(Debug, Default, Clone, Copy)]
pub struct StdTorLauncher;

impl TorLauncher for StdTorLauncher {
    fn launch(&self, plan: &TorLaunchPlan) -> std::io::Result<u32> {
        let child = std::process::Command::new(&plan.tor_binary)
            .args(plan.args())
            .spawn()?;
        Ok(child.id())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_minimal_args() {
        let plan = TorLaunchPlan::new("/usr/bin/tor", "/data/torrc", "/data/tor");
        assert_eq!(
            plan.args(),
            vec![
                "-f".to_string(),
                "/data/torrc".to_string(),
                "--DataDirectory".to_string(),
                "/data/tor".to_string(),
            ]
        );
    }

    #[test]
    fn appends_owning_controller_pid() {
        let plan = TorLaunchPlan::new("tor", "torrc", "data").with_owning_controller(4242);
        let args = plan.args();
        let pos = args
            .iter()
            .position(|a| a == "--__OwningControllerProcess")
            .expect("flag present");
        assert_eq!(args[pos + 1], "4242");
    }

    /// A fake launcher proving the trait seam is usable without spawning tor.
    struct RecordingLauncher {
        last_args: std::cell::RefCell<Vec<String>>,
    }

    impl TorLauncher for RecordingLauncher {
        fn launch(&self, plan: &TorLaunchPlan) -> std::io::Result<u32> {
            *self.last_args.borrow_mut() = plan.args();
            Ok(1234)
        }
    }

    #[test]
    fn launcher_trait_is_fakeable() {
        let launcher = RecordingLauncher {
            last_args: std::cell::RefCell::new(Vec::new()),
        };
        let plan = TorLaunchPlan::new("tor", "torrc", "data");
        let pid = launcher.launch(&plan).expect("launch");
        assert_eq!(pid, 1234);
        assert_eq!(launcher.last_args.borrow().len(), 4);
    }
}
