from captcha.image import ImageCaptcha
import random
import string
import os
import datetime

# captcha properties
captcha_amount = 300

# captcha png properties
img_width = 280
img_height = 90
char_amount = 5
charset = string.ascii_letters + string.digits

# generate base image
image = ImageCaptcha(img_width, img_height)

# create timestamp directory
foldername = f"{datetime.datetime.now()}"

# create directory with unique name
if not os.path.exists(f"./{foldername}"):
    os.makedirs(f"./{foldername}")

for x in range(captcha_amount):
    captcha_text = "".join(random.choices(charset, k=char_amount))
    captcha = image.generate(captcha_text)
    filename = f"{captcha_text}.png"
    image.write(captcha_text, f"./{foldername}/{filename}")
