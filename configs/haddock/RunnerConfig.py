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

from typing import Dict, List, Any, Optional
from pathlib import Path
from os.path import dirname, realpath

from pprint import pprint

'''
From https://github.com/haddocking/haddock3/blob/main/examples/run_examples-full.py
We pick one example from every type, others are commented out. This way we can test a broad
range of HADDOCK capabilities, while limiting the number of runs and thereby the runtime            Baseline times running 1 "full"             "Test" counterpart:
of the experiment, which would otherwise exceed our available time.                                 instance with 32 cores, in seconds:         
'''
HADDOCK_EXAMPLES = (
    ("docking-protein-DNA"         , "docking-protein-DNA-full.cfg"),                               # 594                                       -         
    # ("docking-protein-DNA"         , "docking-protein-DNA-cltsel-full.cfg"),                      # -                                         -
    # ("docking-protein-DNA"         , "docking-protein-DNA-mdref-full.cfg"),                       # -                                         -
    ("docking-protein-homotrimer"  , "docking-protein-homotrimer-full.cfg"),                        # 2833                                      155 (uses up to  5 cores)
    ("docking-protein-ligand"      , "docking-protein-ligand-full.cfg"),                            # 2394                                      221 (uses up to 20 cores, mostly 5)
    # ("docking-protein-ligand-shape", "docking-protein-ligand-shape-full.cfg"),                    # -                                         -
    ("docking-protein-peptide"     , "docking-protein-peptide-full.cfg"),                           # > 1hr (time limit)                        425 (uses up to 18 cores, mostly 5)
    # ("docking-protein-peptide"     , "docking-protein-peptide-cltsel-full.cfg"),                  # -                                         -
    # ("docking-protein-peptide"     , "docking-protein-peptide-mdref-full.cfg"),                   # -                                         -
    ("docking-protein-protein"     , "docking-protein-protein-full.cfg"),                           # 1100                                      -                                       
    # ("docking-protein-protein"     , "docking-protein-protein-cltsel-full.cfg"),                  # -                                         -
    # ("docking-protein-protein"     , "docking-protein-protein-mdref-full.cfg"),                   # -                                         - 
    ("docking-multiple-ambig"      , "docking-multiple-tbls-clt-full.cfg"),                         # > 1hr (time limit)                        353 (uses up to 18 cores)
    ("docking-antibody-antigen"    , "docking-antibody-antigen-CDR-NMR-CSP-full.cfg"),              # 2723                                      -
    # ("docking-antibody-antigen"    , "docking-antibody-antigen-CDR-accessible-full.cfg"),         # -                                         -
    # ("docking-antibody-antigen"    , "docking-antibody-antigen-CDR-accessible-clt-full.cfg"),     # -                                         -
    # ("docking-antibody-antigen"    , "docking-antibody-antigen-ranairCDR-full.cfg"),              # ~2 hrs                                    -
    # ("docking-antibody-antigen"    , "docking-antibody-antigen-ranairCDR-clt-full.cfg"),          # -                                         -
    ("peptide-cyclisation"         , "cyclise-peptide-full.cfg"),                                   # 1231                                      -
)

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name:                       str             = "new_runner_experiment"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment. (Path does not need to exist - it will be created if necessary.)
    Output path defaults to the config file's path, inside the folder 'experiments'"""
    results_output_path:        Path            = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type:             OperationType   = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms:    int             = 1000

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

        output.console_log("Custom config loaded")

    def create_run_table_model(self) -> RunTableModel:
        """Create and return the run_table model here. A run_table is a List (rows) of tuples (columns),
        representing each run performed"""

        # Haddock examples jobs: https://www.bonvinlab.org/haddock3/examples.html
        factor1 = FactorModel("haddock_job", [
            "docking-protein-DNA-full",
            "docking-protein-protein-full",
            "cyclise-peptide-full"
        ])
        factor2 = FactorModel("treatment", ["sequential", "parallel"])

        self.run_table_model = RunTableModel(
            factors=[factor1, factor2],
            data_columns=['energy_usage', 'execution_time', 'memory_usage', 'cpu_usage'],
            repetitions=10,
        )

        return self.run_table_model

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment here
        Invoked only once during the lifetime of the program."""

        output.console_log("Config.before_experiment() called!")

    def before_run(self) -> None:
        """Perform any activity required before starting a run.
        No context is available here as the run is not yet active (BEFORE RUN)"""

        output.console_log("Config.before_run() called!")

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run here.
        For example, starting the target system to measure.
        Activities after starting the run should also be performed here."""

        output.console_log("Config.start_run() called!")

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements."""
        output.console_log("Config.start_measurement() called!")

    def interact(self, context: RunnerContext) -> None:
        """Perform any interaction with the running target system here, or block here until the target finishes."""

        output.console_log("Config.interact() called!")

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements."""

        output.console_log("Config.stop_measurement called!")

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run.
        Activities after stopping the run should also be performed here."""

        output.console_log("Config.stop_run() called!")

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
