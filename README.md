# Fluid Balance Estimation in MIMIC-IV
A re-adaptation of the code found in [mimic-iv/concepts/fluid-balance](https://github.com/MIT-LCP/mimic-code/tree/fluid-balance/mimic-iv/concepts/fluid-balance).  
Tested on BigQuery, MIMIC-IV version 2.2.

### Installation 
Run:   
```python
pip install "git+https://github.com/jhn-nt/mimic-iv__fluid-balance.git"
```

### QuicStart
To generate the `<your project-id>.mimiciv_derived.fluid_balance` table in your BigQuery, run:
```python
python3 -m mimiciv__fluid_balance -p <your project-id>
```



## Acknowledgements
1. Johnson, Alistair, et al. "Mimic-iv." PhysioNet. Available online at: https://physionet. org/content/mimiciv/1.0/(accessed August 23, 2021) (2020).  
2. Johnson, Alistair EW, et al. "MIMIC-IV, a freely accessible electronic health record dataset." Scientific data 10.1 (2023): 1.
3. Johnson, Alistair EW, et al. "MIMIC-III, a freely accessible critical care database." Scientific data 3.1 (2016): 1-9.