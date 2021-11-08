import os
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image as img
from keras.preprocessing.image import img_to_array
from keras import backend as k
import numpy as np
import tensorflow as tf
from PIL import Image
# from keras import decode_predictions,preprocess_input
from datetime import datetime
import io
from flask import Flask,Blueprint,request,render_template,jsonify

def run_tflite_model(tflite_file, test_image):
    
    interpreter = tf.lite.Interpreter(model_path=str(tflite_file))
    interpreter.allocate_tensors()
    print(interpreter.get_input_details())
    input_details = interpreter.get_input_details()[0]
    print(input_details)
    output_details = interpreter.get_output_details()[0]

    interpreter.set_tensor(input_details["index"], test_image)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details["index"])[0]
    # prediction = output.argmax()

    return output

mod = Blueprint('backend',__name__,template_folder='templates',static_folder='./static')
UPLOAD_URL = 'http://192.168.1.103:5000/static/'

@mod.route('/')
def home():
    
 
    return render_template('index.html')

@mod.route('/predict' ,methods=['POST','GET'])
def predict(): 
    direc = os.getcwd()
    path = os.path.join(direc,'modules/static/2.jpg') 
    if request.method == 'POST':
        # check if the post request has the file part
        print(request.files)
        if 'file' not in request.files:
           return "someting went wrong 1"
      
        user_file = request.files['file']
        temp = request.files['file']
        if user_file.filename == '':
            return "file name not found ..." 
        user_file.save(path)
       
        
        
    classes = identifyImage(path)
    labels = ["Apex", "DES"]
    jsondict = {}
    for i in range(len(labels)):
        jsondict[labels[i]] = str(classes[i])
    jsondict['Prediction'] = labels[classes.argmax()]
    print(jsondict)
    return jsonify(jsondict)
          


def identifyImage(img_path):
   
    image = img.load_img(img_path)
    w, h = image.size
    if image.size == (1080, 1920):
        image = image.transpose(Image.ROTATE_90)
    image = image.resize((224,224))
    x = img_to_array(image)
    x = np.expand_dims(x, axis=0)
    # images = np.vstack([x])
    x = x / 255.
    direc = os.getcwd()
    path = os.path.join(direc,'modules/backed/inMap-mobile.tflite')
    preds = run_tflite_model(path,x)
    
    return  preds
            

   




            
           
          


