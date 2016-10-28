#!/bin/bash
mix deps.get
mix deps.compile
mix escript.build
