running pip on a container gives this warning:

WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager, possibly rendering your system unusable.It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv. Use the --root-user-action option if you know what you are doing and want to suppress this warning.

WORKDIR creates the directory as root, and COPY sets the copied files and directories owners to root, even after USER is executed to set the user to a non-root user.


Then, there is this warning:

Step 12/12 : RUN cd /app && pip install .
 ---> Running in f2b1f4644658
WARNING: The directory '/home/konnichiwa/.cache/pip' or its parent directory is not owned or is not writable by the current user. The cache has been disabled. Check the permissions and owner of that directory. If executing pip with sudo, you should use sudo's -H flag.

https://stackoverflow.com/questions/68155641/should-i-run-things-inside-a-docker-container-as-non-root-for-safety





There are several ways to deploy the app to AWS:

1. EC2 + manual Docker installation
2. ECS + ECR
3. Fargate
4. EKS



