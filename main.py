from apig_wsgi import make_lambda_handler
from searx.webapp import app

lambda_handler = make_lambda_handler(app)
