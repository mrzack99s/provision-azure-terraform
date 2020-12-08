from netmiko import ConnectHandler
user = "user"
passwd = "passwd"

s_pip = 'x.x.x.x'
e_pip = 'x.x.x.x'

device1 = {
    'device_type': 'linux',
    'ip': s_pip,
    'username': user,
    'password': passwd,
    'secret': passwd,
    'port': '22'
}

device2 = {
    'device_type': 'linux',
    'ip': s_pip,
    'username': user,
    'password': passwd,
    'secret': passwd,
    'port': '2222'
}

device3 = {
    'device_type': 'linux',
    'ip': e_pip,
    'username': user,
    'password': passwd,
    'secret': passwd,
    'port': '22'
}

device4 = {
    'device_type': 'linux',
    'ip': e_pip,
    'username': user,
    'password': passwd,
    'secret': passwd,
    'port': '2222'
}

c1 = ConnectHandler(**device1)
c2 = ConnectHandler(**device2)
c3 = ConnectHandler(**device3)
c4 = ConnectHandler(**device4)

try:
    print("Setting up device1")
    c1.enable(cmd="sudo su", pattern='password')
    c1.send_command("curl -fsSL https://get.docker.com | bash")
    c1.send_command("systemctl enable docker")
    c1.send_command("usermod -aG docker " + user)
    c1.send_command("docker run -p 80:80 -d --restart always mrzack/test-hub-spoke-sasia:latest")
    c1.exit_enable_mode()
except:
    pass


try:
    print("Setting up device2")
    c2.enable(cmd="sudo su", pattern='password')
    c2.send_command("curl -fsSL https://get.docker.com | bash")
    c2.send_command("systemctl enable docker")
    c2.send_command("usermod -aG docker " + user)
    c2.send_command("docker run -p 80:80 -d --restart always mrzack/test-hub-spoke-sasia:latest")
    c2.exit_enable_mode()
except:
    pass

try:
    print("Setting up device3")
    c3.enable(cmd="sudo su", pattern='password')
    c3.send_command("curl -fsSL https://get.docker.com | bash")
    c3.send_command("systemctl enable docker")
    c3.send_command("usermod -aG docker " + user)
    c3.send_command("docker run -p 80:80 -d --restart always mrzack/test-hub-spoke-easia:latest")
    c3.exit_enable_mode()
except:
    pass

try:
    print("Setting up device4")
    c4.enable(cmd="sudo su", pattern='password')
    c4.send_command("curl -fsSL https://get.docker.com | bash")
    c4.send_command("systemctl enable docker")
    c4.send_command("usermod -aG docker " + user)
    c4.send_command("docker run -p 80:80 -d --restart always mrzack/test-hub-spoke-easia:latest")
    c4.exit_enable_mode()
except:
    pass