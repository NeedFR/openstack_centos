#!/bin/bash
adduser austin;
adduser tim;
adduser morinor;
adduser zhaox;

usermod -G wheel austin;
usermod -G wheel tim;
usermod -G wheel morinor;
usermod -G wheel zhaox;

mkdir -p /home/austin/.ssh;
mkdir -p /home/tim/.ssh;
mkdir -p /home/morinor/.ssh;
mkdir -p /home/zhaox/.ssh;

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrDk4/PLhFjPPL8En/VV/+VLzl31NpP2gDkxqin67oC9GhwEBpBYHkGfBpI7VQ1dr7jMRdsX96n8bLWXSlMuqLKxfRHr6NdFjcQdsnL+mwD/dnVnYBXSXP+yCx6ZD37F3EK9Xb2rEMHIFpYBu2a5O0a9EWRD8vOdV3ctF88DNFcUJqeYJlSz5fWzUH4rHZuohKgOZVaGOYztmT5r/Kpjlc7yCPkDDzDKM8hGm9uz03RezQAES1tXHrx6kQwRuANuX+bc+WMKMYAq3pPxpJGJrY4HI5KcTo/w1bWSiLerSqy+iYptW2tRIbAHnZewQHp+yXB22F8ly54SIVwFHANoZz Datacenter h1" > /home/austin/.ssh/authorized_keys;
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgvf86Fr6ozdPX5njWzHPONUrZW6aZNFYK2Vx/ep9AHQvEQRDz2tLlyilTNO6oh15VDzmZIjyAivmef+Rrhgg6zYOjjov+1vF50LDOg/CxRuJ4PiGADbe3hdNzrKcMFuy5PQptIIA71RJCnYzV5Uwq+CvGiONXtb06gC8zIYr+0frCc6pGwAlEUlQA8xtIgDhvfBS5fWw73zXK8i+O2nGsdVimIHHJzLUEWJXk6lF/xCLy98OJj6VCxOMP/6bhJhugqqTTc0NxGY7taekomuIYGGH8dJ9bP/JOeDo2aixzXOEA/D0hgtWGI4/PotgdnC+v1COtf0G0u0keCIkDKryH Tim@Tim-mbp" > /home/tim/.ssh/authorized_keys;
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9MTqE75hHDKPavoYThJpe5DmpDFQROPstHJ4fy39O2Af4/Hzelw1iTPIg84NF12dKgItPxd/XRDMw7iOHHxwFK2qRSt2uYo6lYofeUhv2DrjZOPaQulrPfp/Zbl3lYsiXgQ/5SCS8F1szvcTLTdcEdBiga52vW7N2cwtMmld+9pq3SmqXnr7sGjuKU8qiRyk0DpBYEBafc44hvRKqgmFL71otT8J2Lm6+cs+XEXEd01dw9pDyNjGsFNCownMYtWpSB8A5klbKtu4PkQzwG5/vUoWBkZXss47NxJJsmYdgXbBqGheOx6zwpcWpA263txyqKU41gqM5CS4PbrF0VKCx h1" > /home/morinor/.ssh/authorized_keys;
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgS9V5XfhaQ+r7VElkgSFbMsOB+Ci4O5/J0vPwrVkB/lA+Tza2v+6CZi0HDLGxS6WiD4c4L35RowVdN+TswoRTTI9ZqsGDRXV8XvdLiYYucGaNklf/qe2c8WMuwC0eKqFm/NmZn2ImySZjQyuKY6AUarIVHFLIEDYvYezdVcDM7D5DDRwTiOOEUa5K6nOoRsIAUuQ+q+dikeijtVkITI+DRF/4qyWBTEGjfhhz3507v2cvL5/5ua13JWWW5IoWJOE6jLolaEdAeCGdLNxniAyaINTkf2IA8BC3IsWmjCtULsC9wLNbSD818mV0Wx43Wf8mG5/d/AGL9mSUJirHmJcp zhaox" > /home/zhaox/.ssh/authorized_keys;

chown -R austin:austin /home/austin/.ssh;
chmod 700 /home/austin/.ssh;
chmod 600 /home/austin/.ssh/authorized_keys;
chown -R tim:tim /home/tim/.ssh;
chmod 700 /home/tim/.ssh;
chmod 600 /home/tim/.ssh/authorized_keys;
chown -R morinor:morinor /home/morinor/.ssh;
chmod 700 /home/morinor/.ssh;
chmod 600 /home/morinor/.ssh/authorized_keys;
chown -R zhaox:zhaox /home/zhaox/.ssh;
chmod 700 /home/zhaox/.ssh;
chmod 600 /home/zhaox/.ssh/authorized_keys;

AUSTIN="austin:\$6\$Wdggqyms\$m9tmZbujC1ZBW5i1\/zcNfvNpHpyBsQgSYgefhM4GazfjNCs\/ixwlq99a8.HwwOFqK88U4ItubmWDgZMvUL69z1:16211:0:99999:7:::";
TIM="tim:\$6\$bCwmztR.\$3QC39a1AjfAwfFT\/KnjfX7v6uRNHlb6zccZjlH8uPn7E4jfvb1NpYQXrnonIO7mdviOrIxZwl5cN3u0ygi5Xm1:16209:0:99999:7:::";
MORINOR="morinor:\$6\$8TlWwW2I\$eQWmKarbW.iSrD2953y9tzWtosHd8PNO8b6CbLDwxZMGQylHAJXQHbsUhyAHfB.NRMvIzxCtXV1xuKkWy.v4I1:16209:0:99999:7:::";
ZHAOX="zhaox:\$6\$ZTbFXwgF\$c6pN9xBgwzgkKMMmlbvwpHTn1mWSdy8sojBnYoVtA1ckpTaWS8j5TMraslyw60aCVmJh9zR\/X6X3FqB.9DBa20:16209:0:99999:7:::";

sed -i "s/^austin.*$/$AUSTIN/g" /etc/shadow;
sed -i "s/^tim.*$/$TIM/g" /etc/shadow;
sed -i "s/^morinor.*$/$MORINOR/g" /etc/shadow;
sed -i "s/^zhaox.*$/$ZHAOX/g" /etc/shadow;