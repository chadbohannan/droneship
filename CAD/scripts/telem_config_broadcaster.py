import time
import socket
import sys


def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('255.255.255.255', 1))
        return s.getsockname()[0]
    except:
        return '127.0.0.1'
    finally:
        s.close()


def bcast_advert(advert, bcast_address, port):
    udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    udpSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    udpSocket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    udpSocket.sendto(advert.encode('utf-8'), (bcast_address, port))


def main(ip_address):
    local_ip=get_local_ip()
    bcast_address = '.'.join(local_ip.split('.')[:3]) + '.255'
    print('broadcasting:' + ip_address + ' to:' + bcast_address)
    bcast_advert(ip_address, bcast_address, 8083)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        main(get_local_ip())