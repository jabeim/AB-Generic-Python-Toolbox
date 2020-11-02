# -*- coding: utf-8 -*-

from setuptools import setup

setup(name='GpyT',
      version = '0.1',
      description = 'an advanced bionics cochlear implant simulator',
      url = '',
      author = 'JAB',
      author_email='beimx004@umn.edu',
      license='GNU GPL v3',
      packages=['GpyT'],
      install_requires=[
              'numpy >= 1.16.2, <= 1.19.2',
              'scipy >= 1.2.1, <= 1.5.2',
              'nnresample >= 0.2.4',
              'numba >= 0.43.1, <= 0.51.2',
              'pyaudio > 0.2.10',
              'h5py'],
      zip_safe=False)
