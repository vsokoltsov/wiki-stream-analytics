from setuptools import setup, find_packages

setup(
    name="wiki-stream-analytics",
    version="0.1.0",
    packages=find_packages(include=["ingestion", "ingestion.*"]),
)