#!/bin/bash
# Add boxes to known hosts to avoid the security question.
#
ssh-keyscan -t rsa sig-rdbms-junta.test sig-rdbms-com.test > .ssh/known_hosts
ssh-keyscan -t dsa sig-rdbms-junta.test sig-rdbms-com.test >> .ssh/known_hosts
