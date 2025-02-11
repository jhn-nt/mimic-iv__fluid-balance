from setuptools import setup

setup(
    name="mimiciv__fluid_balance",
    version="0.3",
    author="G. Angelotti, MSc",
    packages=["mimiciv__fluid_balance"],
    include_package_data=True,
    install_requires=["google-cloud-bigquery==3.13.0"]
)