# Green Lab 2024 replication package

This is the replication package for the project submission of team *name of the team* for the 2024 edition of the Green Lab course. Our goal is identify The performance and energy efficiency impact of parallelising
the execution of jobs in High Performance Computing (HPC) domain. In particular, using SLURM, we run a number of [haddock3](https://github.com/haddocking/haddock3) jobs using different splits of core counts per group of jobs and measure the energy and energy usage, the CPU utilisation and the execution time, to identify how different paralellisation splits affect these metrics. 

## Architecture

The architecture of the framework is illustrated in the below diagram:

![Architecture](./figures/architecture.png)

## Requirements

The framework has been tested with Python3 version 3.8, but should also work with any higher version. It has been tested under Linux and macOS. It does **not** work on Windows (at the moment).

The experiment requires two servers: one for dispatching jobs using SLURM (`S1`) and one purely dedicated to executing these jobs (the HPC instance, `S2`). SLURM must be setup on these servers such that jobs can be queued by `S1` to be executed on `S2`.

### 1. Set up experiment runner
This step should be performed on server `S1`, i.e. the dispatcher.

Clone this repo:

```bash
git clone git@github.com:andrulonis/Green-Lab.git
cd Green-Lab
```

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

### 2. Set up HADDOCK
This step should be performed on server `S2`, i.e. the high performance job executor.

Install **haddock3** by following the HADDOCK3 install instructions:
https://github.com/haddocking/haddock3/blob/main/docs/INSTALL.md.

## Running

In this section, we assume as the current working directory, the root directory of the project.

Run our HADDOCK config:

```bash
python experiment-runner/ configs/haddock/RunnerConfig.py
```

The results of the experiment will be stored in the directory `configs/haddock/experiments`.

Note that once you successfully run an experiment, the framework will not allow you to run the same experiment again. Remove the `experiments` directory under `configs/haddock/experiments` if you are sure you want to restart the experiment.

