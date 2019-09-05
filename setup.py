from setuptools import setup

setup(name='protobuf-solidity',
      version='0.1',
      description='ProtoBuf compiler for Solidity',
      url='https://github.com/nutsfinance/solidity-protobuf/',
      author='Frank Yin',
      author_email='ukby.1234@gmail.com',
      license='MIT',
      include_package_data=True,
      packages=['protobuf-solidity'],
      scripts=['protobuf-solidity/bin/solidity-protobuf'],
      install_requires=[
          'protobuf>=3.0.0',
      ],
      zip_safe=False)
