import shlex
import subprocess
import time
from EventManager.Models.RunnerEvents import RunnerEvents
from EventManager.EventSubscriptionController import EventSubscriptionController
from ConfigValidator.Config.Models.RunTableModel import RunTableModel
from ConfigValidator.Config.Models.FactorModel import FactorModel
from ConfigValidator.Config.Models.RunnerContext import RunnerContext
from ConfigValidator.Config.Models.OperationType import OperationType
from ExtendedTyping.Typing import SupportsStr
from ProgressManager.Output.OutputProcedure import OutputProcedure as output

from typing import Dict, List, Any, Optional, Tuple
from pathlib import Path
from os.path import dirname, realpath

from string import Template
from pprint import pprint
import shutil
import os

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    '''
    From https://github.com/haddocking/haddock3/blob/main/examples/run_examples-full.py
    We pick one example from every type, others are commented out. This way we can test a broad
    range of HADDOCK capabilities, while limiting the number of runs and thereby the runtime            Baseline times running 1 "full"             "test" counterpart:
    of the experiment, which would otherwise exceed our available time.                                 instance with 32 cores, in seconds:         
    '''
    HADDOCK_JOBS: Dict[str, str] = {
          "docking-protein-DNA"         : "docking-protein-DNA-full.cfg",                             # 594                                       -         
        # "docking-protein-DNA"         : "docking-protein-DNA-cltsel-full.cfg",                      # -                                         -
        # "docking-protein-DNA"         : "docking-protein-DNA-mdref-full.cfg",                       # -                                         -
        # "docking-protein-homotrimer"  : "docking-protein-homotrimer-full.cfg",                      # 2833                                      155 (uses up to  5 cores)
        # "docking-protein-ligand"      : "docking-protein-ligand-full.cfg",                          # 2394                                      221 (uses up to 20 cores, mostly 5)
        # "docking-protein-ligand-shape": "docking-protein-ligand-shape-full.cfg",                    # -                                         -
        # "docking-protein-peptide"     : "docking-protein-peptide-full.cfg",                         # > 1hr (time limit)                        425 (uses up to 18 cores, mostly 5)
        # "docking-protein-peptide"     : "docking-protein-peptide-cltsel-full.cfg",                  # -                                         -
        # "docking-protein-peptide"     : "docking-protein-peptide-mdref-full.cfg",                   # -                                         -
          "docking-protein-protein"     : "docking-protein-protein-full.cfg",                         # 1100                                      -                                       
        # "docking-protein-protein"     : "docking-protein-protein-cltsel-full.cfg",                  # -                                         -
        # "docking-protein-protein"     : "docking-protein-protein-mdref-full.cfg",                   # -                                         - 
        # "docking-multiple-ambig"      : "docking-multiple-tbls-clt-full.cfg",                       # > 1hr (time limit)                        353 (uses up to 18 cores)
        # "docking-antibody-antigen"    : "docking-antibody-antigen-CDR-NMR-CSP-full.cfg",            # 2723                                      -
        # "docking-antibody-antigen"    : "docking-antibody-antigen-CDR-accessible-full.cfg",         # -                                         -
        # "docking-antibody-antigen"    : "docking-antibody-antigen-CDR-accessible-clt-full.cfg",     # -                                         -
        # "docking-antibody-antigen"    : "docking-antibody-antigen-ranairCDR-full.cfg",              # ~2 hrs                                    -
        # "docking-antibody-antigen"    : "docking-antibody-antigen-ranairCDR-clt-full.cfg",          # -                                         -
          "peptide-cyclisation"         : "cyclise-peptide-full.cfg",                                 # 1231                                      -
    }

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name:                       str             = "HPC_Haddock"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment. (Path does not need to exist - it will be created if necessary.)
    Output path defaults to the config file's path, inside the folder 'experiments'"""
    results_output_path:        Path            = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type:             OperationType   = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms:    int             = 1000 # * 60 * 2  # 2 minutes

    # Dynamic configurations can be one-time satisfied here before the program takes the config as-is
    # e.g. Setting some variable based on some criteria
    def __init__(self):
        """Executes immediately after program start, on config load"""

        EventSubscriptionController.subscribe_to_multiple_events([
            (RunnerEvents.BEFORE_EXPERIMENT, self.before_experiment),
            (RunnerEvents.BEFORE_RUN       , self.before_run       ),
            (RunnerEvents.START_RUN        , self.start_run        ),
            (RunnerEvents.START_MEASUREMENT, self.start_measurement),
            (RunnerEvents.INTERACT         , self.interact         ),
            (RunnerEvents.STOP_MEASUREMENT , self.stop_measurement ),
            (RunnerEvents.STOP_RUN         , self.stop_run         ),
            (RunnerEvents.POPULATE_RUN_DATA, self.populate_run_data),
            (RunnerEvents.AFTER_EXPERIMENT , self.after_experiment )
        ])
        self.run_table_model = None  # Initialized later
        self.failed = False

        output.console_log("Custom config loaded")

    def create_run_table_model(self) -> RunTableModel:
        """Create and return the run_table model here. A run_table is a List (rows) of tuples (columns),
        representing each run performed"""

        # Haddock examples jobs: https://www.bonvinlab.org/haddock3/examples.html
        factor1 = FactorModel("haddock_job", RunnerConfig.HADDOCK_JOBS.keys())
        factor2 = FactorModel("treatment", ["sequential", "parallel"])

        self.run_table_model = RunTableModel(
            factors=[factor1, factor2],
            data_columns=['energy_usage', 'execution_time', 'memory_usage', 'cpu_usage'],
            repetitions=10,
            shuffle=True
        )

        return self.run_table_model

    def get_environment_variable(self, key: str) -> str:
        """Return the value of the environment variable with the given key.
        If the environment variable is not set, raise a KeyError"""
        value = os.environ.get(key)

        if value is None:
            raise KeyError(f"Environment variable {key} not found")

        return value

    def slurm_get_job_status(self) -> str:
        cmd = shlex.split(f"{self.ROOT_DIR / 'get-job-status.sh'} {self.job_id}")

        return subprocess.check_output(cmd).decode()[:-1]

    def slurm_wait_for_status(self, status_options: List[str], wait_delay: int = 5) -> bool:
        cur_status = self.slurm_get_job_status()
        error_states = ("FAILED",  "CANCELLED", "DEADLINE", "REVOKED", "STOPPED", "SUSPENDED", "TIMEOUT")

        while cur_status not in status_options:
            if cur_status in error_states:
                return False

            output.console_log(f"Waiting {wait_delay} seconds for status {' or '.join(status_options)} on job {self.job_id}, current status: {cur_status}")
            time.sleep(wait_delay)
            cur_status = self.slurm_get_job_status()

        return True

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment here
        Invoked only once during the lifetime of the program."""

        output.console_log("Config.before_experiment() called!")

        # There should be a shared directory for storing results
        self.shared_dir = self.ROOT_DIR / 'shared'
        if not self.shared_dir.exists():
            raise FileNotFoundError(f"Shared directory {self.shared_dir} not found, please follow the README instructions")

        shared_cfg_dir = self.shared_dir / 'jobs'
        if not shared_cfg_dir.exists():
            shared_cfg_dir.mkdir()
            output.console_log(f"Created HADDOCK jobs directory: {shared_cfg_dir}")

        for base_dir in RunnerConfig.HADDOCK_JOBS:
            cfg_dir = self.ROOT_DIR / 'haddock-workflows' / base_dir
            cfg_dir_dest = shared_cfg_dir / base_dir

            if not cfg_dir.exists():
                raise FileNotFoundError(f"Directory {cfg_dir} not found")

            if cfg_dir_dest.exists():
                output.console_log_WARNING(f"{cfg_dir_dest} already exists, skipping copy")
                continue

            output.console_log(f"Copying {cfg_dir} to shared directory")
            shutil.copytree(cfg_dir, cfg_dir_dest)     

        outfiles_dir = self.shared_dir / 'out'
        if not outfiles_dir.exists():
            outfiles_dir.mkdir()
            output.console_log(f"Created HADDOCK output directory: {outfiles_dir}")

        self.slurm_scripts_dir = self.ROOT_DIR / 'slurm-scripts'
        if not self.slurm_scripts_dir.exists():
            self.slurm_scripts_dir.mkdir()
            output.console_log(f"Created SLURM scripts directory: {self.slurm_scripts_dir}")

    def before_run(self) -> None:
        """Perform any activity required before starting a run.
        No context is available here as the run is not yet active (BEFORE RUN)"""

        output.console_log("Config.before_run() called!")

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run here.
        For example, starting the target system to measure.
        Activities after starting the run should also be performed here."""
        output.console_log("Config.start_run() called!")

        slurm_job_template = self.ROOT_DIR / 'slurm-job-template.sh'
        if not slurm_job_template.exists():
            raise FileNotFoundError(f"Slurm job template {slurm_job_template} not found")
        slurm_job_template = Template(slurm_job_template.read_text())

        run_id = context.run_variation['__run_id']
        cpus_per_task = 8 if context.run_variation['treatment'] == 'parallel' else 32
        worker_shared_dir = Path(self.get_environment_variable('WORKER_NODE_SHARED_DIR'))
        haddock_job_dir = context.run_variation['haddock_job']

        # Create SLURM job script
        slurm_job_script = slurm_job_template.safe_substitute(
            job_name = run_id,
            cpus_per_task = cpus_per_task,
            ntasks = 1 if cpus_per_task == 32 else 4,
            shared_dir = worker_shared_dir,
            cfg_dir = haddock_job_dir,
            cfg_file = RunnerConfig.HADDOCK_JOBS[haddock_job_dir],
            node = self.get_environment_variable('WORKER_NODE_NAME'),
            working_dir = self.get_environment_variable('WORKER_NODE_WORKING_DIR'),
            haddock3_venv_dir = self.get_environment_variable('WORKER_NODE_HADDOCK_VENV_DIR'),
        )

        self.slurm_job_script_path = self.slurm_scripts_dir / f"{run_id}.sh"
        self.slurm_job_script_path.write_text(slurm_job_script)

        # Submit SLURM job
        output.console_log(f"Submitting SLURM job {self.slurm_job_script_path}")
        success = subprocess.check_output(shlex.split(f"sbatch {self.slurm_job_script_path}")).decode()
        self.job_id = int(success.split()[-1])
        output.console_log(f"Batch job started with job ID {self.job_id}")

        # Wait for the job to start running
        if not self.slurm_wait_for_status(["RUNNING", "COMPLETED"]):
            output.console_log_FAIL(f"Job {self.job_id} failed!")
            self.failed = True
            return

        output.console_log(f"Job {run_id} successfully started")

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements."""
        output.console_log("Config.start_measurement() called!")

    def interact(self, context: RunnerContext) -> None:
        """Perform any interaction with the running target system here, or block here until the target finishes."""

        output.console_log("Config.interact() called!")

        if self.failed:
            return

        job_name = context.run_variation['__run_id']

        # Wait for SLURM job to finish
        if not self.slurm_wait_for_status(["COMPLETED"], wait_delay=30):
            output.console_log_FAIL(f"Job {self.job_id} failed!")
            self.failed = True
            return
        output.console_log(f"Job {job_name} completed successfully")

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements."""

        output.console_log("Config.stop_measurement called!")

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run.
        Activities after stopping the run should also be performed here."""
        output.console_log("Config.stop_run() called!")

        # Remove SLURM job script
        self.slurm_job_script_path.unlink()

    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, SupportsStr]]:
        """Parse and process any measurement data here.
        You can also store the raw measurement data under `context.run_dir`
        Returns a dictionary with keys `self.run_table_model.data_columns` and their values populated"""

        output.console_log("Config.populate_run_data() called!")
        return None

    def after_experiment(self) -> None:
        """Perform any activity required after stopping the experiment here
        Invoked only once during the lifetime of the program."""

        output.console_log("Config.after_experiment() called!")

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path:            Path             = None
