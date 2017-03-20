#!/bin/bash
# Add boxes to known hosts to avoid the security question.
#
ssh-keyscan -t rsa ly-rdbms-yin.test ly-rdbms-yang.test > .ssh/known_hosts
ssh-keyscan -t dsa ly-rdbms-yin.test ly-rdbms-yang.test >> .ssh/known_hosts
