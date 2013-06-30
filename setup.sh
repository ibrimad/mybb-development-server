#!/bin/bash

vagrant halt && vagrant up && vagrant ssh -c "sudo service httpd restart" && vagrant ssh -c "echo '$(cat ~/.gitconfig)' > .gitconfig"
