#!/bin/bash
lbdbq $* | perl -F'\t' -lane '$F[1] =~ s/\s*([^,]+),\s*([^,]+)/\2 \1/; print join("\t", @F)'
