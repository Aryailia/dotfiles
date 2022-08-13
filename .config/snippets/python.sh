# https://godatadriven.com/blog/a-practical-guide-to-using-setup-py
addPrefixedFunction 'python' 'setup' 'Setup with dev dependencies'
python_setup() {
  <<EOF cat -
from setuptools import setup, find_packages
setup(
    name      = '<>',
    version   = '0.1.0',
    packages  = find_packages(include[]),

    # Production dependencies
    # Install without dev dependencies
    #     pip install -e .
    install_requires = [
        '<>>=<>',
        '<>==<>',
    ],

    # Developer dependencies
    # Install dev dependencies via:
    #     pip install -e .[dev]
    extra_requies=[
        'dev': [
            '<>==<>',
        ]
    ],
EOF
}

# https://godatadriven.com/blog/a-practical-guide-to-using-setup-py
addPrefixedFunction 'python' 'init' 'Init'
python_init() {
  <<EOF cat -
import

def main():
    pass

if __name__ == "__main__":
    main()
EOF
}
