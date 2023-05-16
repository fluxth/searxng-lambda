from asgiref.wsgi import WsgiToAsgi
from mangum import Mangum
from searx.webapp import app

asgi_app = WsgiToAsgi(app)
lambda_handler = Mangum(asgi_app, lifespan="off")
