#!/usr/bin/env python3
"""
Reusable components for data processing in Kubeflow Pipelines.
"""

from kfp import dsl

@dsl.component
def say_hello(name: str) -> str:
    hello_text = f'Hello, {name}!'
    print(hello_text)
    return hello_text
