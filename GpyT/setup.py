# -*- coding: utf-8 -*-

from setuptools import setup

setup(name='virtualci',
      version = '0.1',
      description = 'an advanced bionics cochlear implant simulator',
      url = '',
      author = 'JAB',
      author_email='beimx004@umn.edu',
      license='MIT',
      packages=['virtualci'],
      install_requires=[
              'numpy',
              'scipy',
              'nnresample',]
      zip_safe=False)
