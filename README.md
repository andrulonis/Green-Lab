# Experiment-Runner

## Requirements

The framework has been tested with Python3 version 3.8, but should also work with any higher version. It has been tested under Linux and macOS. It does **not** work on Windows (at the moment).

To get started:

Create and activate a virtual environment:
```bash
python -m venv .venv
. .venv/bin/activate
```

Install the requirements:

```bash
pip install -r requirements.txt
```

To verify installation, run:

```bash
python experiment-runner/ examples/hello-world/RunnerConfig.py
```

## Running

In this section, we assume as the current working directory, the root directory of the project.

Run our [haddock3](https://github.com/haddocking/haddock3) config:

```bash
python experiment-runner/ configs/haddock/RunnerConfig.py
```

The results of the experiment will be stored in the directory `configs/haddock/experiments`.

Note that once you successfully run an experiment, the framework will not allow you to run the same experiment again. Remove the `experiments` directory under `configs/haddock/experiments` if you are sure you want to restart the experiment.

