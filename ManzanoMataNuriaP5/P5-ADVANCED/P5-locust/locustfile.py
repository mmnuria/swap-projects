from locust import HttpUser, task, between
from bs4 import BeautifulSoup

class WordPressUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        self.login()

    def login(self):
        # Simula inicio de sesión de un usuario
        response = self.client.post(
            "/login",
            data={"username": "admin", "password": "admin123"},
            verify=False,
            allow_redirects=True,
        )
        if response.status_code != 200:
            print("Error al iniciar sesión")

    @task(2)
    def visitar_pagina_principal(self):
        self.client.get("/", verify=False)

    @task(2)
    def navegar_articulos(self):
        articulo_id = 20
        self.client.get(f"/articulo/{articulo_id}", verify=False)

    @task(1)
    def crear_comentario(self):
        articulo_id = 2
        comentario = f"Comentario de prueba 2"
        self.client.post(
            f"/articulo/{articulo_id}/comentario",
            data={"comentario": comentario},
            verify=False
        )

    @task(1)
    def publicar_noticia(self):
        titulo = f"Noticia de prueba 2"
        contenido = "Contenido generado automáticamente para pruebas de carga."
        self.client.post(
            "/admin/publicar",
            data={"titulo": titulo, "contenido": contenido},
            verify=False
        )

    @task(1)
    def realizar_busqueda(self):
        consulta = "tecnologia"
        self.client.get(f"/buscar?q={consulta}", verify=False)

    @task(1)
    def cargar_galeria(self):
        self.client.get("/galeria", verify=False)

    @task(1)
    def ver_perfil_usuario(self):
        user_id = 3
        self.client.get(f"/usuario/{user_id}/perfil", verify=False)
