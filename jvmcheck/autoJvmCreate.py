import paramiko
import os
import subprocess
import pipes
import requests

image_check="/home/wasadm/updatedimage.txt"

def main():
    create_jvm()



def create_jvm():

    with open('/usy/jvmcheck/jvm_kurulmamis_sunucular.bash') as f:
        readed_line=str()
        lines = f.readlines()
        for line in lines:
                
            readed_line = str(line)
            host4creating_jvm = readed_line.strip()
            print("If image is updated on this server, JVM will be created. Host is "+host4creating_jvm)
            image_control(host4creating_jvm,image_check)
            print("Operations are done for this host.")
            print("\n\n----------------------------------------------------------------------")
            f.close()
            


def image_control(host, path):
    print("Checking image...")
    """Test if a file exists at path on a host accessible with SSH."""
    status = subprocess.call(
        ['ssh', host, 'test -f {}'.format(pipes.quote(path))])
    if status == 0:
        print("Image is updated on this server")
        response = requests.get("http://klusyman01.isbank:5000/createjvm?host=%s"%host)
        result=response.text.strip()
        print(result)
        statusCode=int(response.status_code)
        if statusCode == 200:
            with open('/usy/jvmcheck/logs/createdJvms.txt', 'a') as f:
                f.write(host)
                f.write('\n')
        else:
        #if result != "Jvm created":
            print("JVM could not be created due to lack of some files.")
        return True
    if status == 1:
        print("Image is not latest version. This image should be updated")
        print("JVM is not created.")
        return False
    else:
        print("SSH failed")
                
            

if __name__ == "__main__":
    main()