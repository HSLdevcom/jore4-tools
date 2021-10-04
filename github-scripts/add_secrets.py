import os
import subprocess
import json

def get_list_of_jore4_repositories():
    response = subprocess.check_output("gh repo list HSLdevcom --topic jore4  --json nameWithOwner", shell=True)
    repositories_as_json = json.loads(response)
    repositories = []
    for repository in repositories_as_json:
      repositories.append(repository['nameWithOwner'])
    return repositories

def set_secret_for_repositories(list_of_repositories, secret_json):
    user_email = secret_json['email']
    user_password = secret_json['password']
    for repository in list_of_repositories:
      subprocess.check_output("gh secret set ROBOT_HSLID_EMAIL  -b\"{}\" --repo {}".format(user_email, repository), shell=True)
      subprocess.check_output("gh secret set ROBOT_HSLID_PASSWORD -b\"{}\" --repo {}".format(user_password, repository), shell=True)
      print(repository)

repositories = get_list_of_jore4_repositories()
secret_file = open('test_users.json',)
secret_json = json.load(secret_file)
set_secret_for_repositories(repositories, secret_json)
