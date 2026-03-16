# ⚡ Nginx Load Balancer Setup

Este projeto fornece um **script Bash simples e robusto** que instala, configura e ativa automaticamente um servidor **Nginx como Load Balancer**, permitindo distribuir requisições entre múltiplos servidores backend.

Ideal para ambientes de **produção, VPS, servidores dedicados ou clusters internos**.

---

# 🚀 Funcionalidades

* Instalação automática do **Nginx**
* Configuração automática de **proxy reverso**
* **Balanceamento de carga**
* Suporte a múltiplos **servidores backend**
* Métodos de balanceamento:

  * `round_robin`
  * `least_conn`
  * `ip_hash`
* Failover automático de servidores
* Suporte a **WebSocket**
* Headers corretos (`X-Forwarded-*`)
* Configuração segura de **timeouts**
* Endpoint de **health check**
* Teste automático da configuração (`nginx -t`)
* Remoção da configuração default do Nginx

---

# 📦 Estrutura do Projeto

```
nginx-load-balancer/
│
├── nginx.sh
└── README.md
```

---

# 🛠 Requisitos

* Linux (Ubuntu, Debian, Rocky, AlmaLinux, CentOS ou Alpine)
* Acesso **root**
* Conectividade com os servidores backend

---

# ⚙️ Instalação

Clone o repositório:

```bash
git clone https://github.com/SEU-USUARIO/nginx-load-balancer.git
cd nginx-load-balancer
```

Dê permissão de execução ao script:

```bash
chmod +x nginx.sh
```

---

# ▶️ Uso

Exemplo básico:

```bash
./nginx.sh
```

O script utilizará configurações padrão.

---

# 🔧 Configuração Avançada

Você pode definir variáveis de ambiente antes da execução.

### Exemplo

```bash
DOMAIN=app.exemplo.com \
UPSTREAM_NAME=cluster_backend \
LB_METHOD=least_conn \
BACKENDS="10.0.0.10:8080 10.0.0.11:8080 10.0.0.12:8080" \
LISTEN_PORT=80 \
./nginx.sh
```

---

# 📊 Métodos de Balanceamento

## Round Robin (padrão)

Distribui requisições igualmente entre os servidores.

```
LB_METHOD=round_robin
```

---

## Least Connections

Envia requisições para o servidor com menos conexões ativas.

```
LB_METHOD=least_conn
```

Recomendado para aplicações com conexões longas.

---

## IP Hash

Mantém afinidade de sessão baseada no IP do cliente.

```
LB_METHOD=ip_hash
```

Ideal para aplicações que precisam de **sticky sessions**.

---

# 🖥 Exemplo de Arquitetura

```
             INTERNET
                 │
                 │
           ┌─────────────┐
           │   NGINX LB  │
           │ ReverseProxy│
           └──────┬──────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Backend 1│ │ Backend 2│ │ Backend 3│
│ 8080     │ │ 8080     │ │ 8080     │
└──────────┘ └──────────┘ └──────────┘
```

---

# 🩺 Endpoint de Health Check

Após a instalação, o Nginx disponibiliza um endpoint simples:

```
http://SEU-SERVIDOR/nginx-health
```

Resposta esperada:

```
ok
```

---

# 🧪 Testes

Teste se o proxy está funcionando:

```bash
curl -I http://localhost
```

ou

```bash
curl http://localhost/nginx-health
```

---

# 🔐 Boas Práticas (Produção)

Recomenda-se adicionar posteriormente:

* HTTPS com **Let's Encrypt**
* Rate limiting
* Cache de conteúdo
* WAF (ModSecurity)
* Logs centralizados
* Monitoramento com **Prometheus + Grafana**

---

# 📈 Casos de Uso

Este projeto pode ser utilizado para:

* Balanceamento de carga para **APIs**
* Infraestrutura de **microserviços**
* Distribuição de tráfego entre **containers**
* Balanceamento de **clusters web**
* Proxy para **aplicações internas**
* Ambientes **DevOps / CI/CD**

---

# 🤝 Contribuição

Contribuições são bem-vindas.

1. Faça um fork do projeto
2. Crie uma branch para sua feature

```bash
git checkout -b minha-feature
```

3. Commit suas alterações

```bash
git commit -m "feat: nova funcionalidade"
```

4. Faça push

```bash
git push origin minha-feature
```

5. Abra um Pull Request.

---

# 📜 Licença

Este projeto está licenciado sob a **MIT License**.

---

# 👨‍💻 Autor

Desenvolvido por **Wellinghton Fernando Armoa Pimenta**

* Ciência da Computação — UFMT
* Infraestrutura Linux
* Segurança de Redes
* DevOps / Sistemas Distribuídos

---
