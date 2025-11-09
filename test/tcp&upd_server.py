import socket
import threading

# -------------------- GLOBALS --------------------
tcp_clients = []
udp_clients = set()  # use a set for unique (ip, port) pairs


# -------------------- TCP HANDLER --------------------
def handle_tcp_client(conn, addr):
    print(f"[TCP] Connected by {addr}")
    while True:
        try:
            data = conn.recv(1024)
            if not data:
                break
            # Broadcast to all TCP clients except sender
            for client in tcp_clients:
                if client != conn:
                    client.send(data)
        except:
            break

    conn.close()
    if conn in tcp_clients:
        tcp_clients.remove(conn)
    print(f"[TCP] Disconnected {addr}")


def start_tcp_server():
    HOST = '0.0.0.0'
    PORT = 8080
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((HOST, PORT))
    server.listen()
    print(f"[TCP] Server listening on {HOST}:{PORT}")

    while True:
        conn, addr = server.accept()
        tcp_clients.append(conn)
        thread = threading.Thread(target=handle_tcp_client, args=(conn, addr))
        thread.start()


# -------------------- UDP HANDLER --------------------
def start_udp_server():
    HOST = '0.0.0.0'
    PORT = 8081
    udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_socket.bind((HOST, PORT))
    print(f"[UDP] Server listening on {HOST}:{PORT}")

    while True:
        data, addr = udp_socket.recvfrom(1024)
        message = data.decode()
        print(f"[UDP] {addr} says: {message}")

        # Add new client if not already tracked
        udp_clients.add(addr)

        # Broadcast to all UDP clients except sender
        for client in udp_clients:
            if client != addr:
                udp_socket.sendto(data, client)


# -------------------- MAIN --------------------
if __name__ == "__main__":
    threading.Thread(target=start_tcp_server, daemon=True).start()
    threading.Thread(target=start_udp_server, daemon=True).start()
    print("✅ TCP and UDP servers are running together...")

    try:
        while True:
            pass
    except KeyboardInterrupt:
        print("\nServer stopped manually.")
