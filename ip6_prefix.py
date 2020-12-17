from netaddr.ip import IPAddress
s = "fe::ffff:fff:2204:fff:feec:dfdc"
if IPAddress(s):
    print("ip address true")
s = s.split(':')
print(s)
p = []
for w in s[:4]:
    if w:
        p.append(w)
    else:
        break
if len(p) < 4:
    p = ":".join(p) + "::/64"
else:
    p = ":".join(p) + "/64"
    
print(p)
