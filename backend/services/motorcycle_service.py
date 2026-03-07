import os
import requests
import urllib.parse
from dotenv import load_dotenv
from pathlib import Path

#_________________________________________
#Find the API key
# 1. find this file
current_file = Path(__file__).resolve()

# 2. find 'backend' folder then look for .env
env_path = current_file.parent.parent/'.env'

# 3. Now we can open the file we're looking for
load_dotenv(dotenv_path=env_path)
#_________________________________________

#Get API key safely
#Goes to the .env file and retrieves 'MOTORCYCLE_API_KEY' value
API_KEY = os.getenv("MOTORCYCLE_API_KEY")

#Safety check
if not API_KEY:
    raise ValueError("No API Key found.")

headers = {
    "X-Api-Key": API_KEY
} #"X-Api-Key" is the specific header for Motorcycles API from Ninjas


def fetch_motorcycle_specs(make: str = "", model: str = ""):

    url = "https://api.api-ninjas.com/v1/motorcycles"
    
    # Search parameters
    query_params = {}
    if make: 
        query_params["make"] = make
    if model: 
        query_params["model"] = model
        
    try:
        # GET request
        response = requests.get(url, headers=headers, params=query_params)
        
        # Raise error if request fails
        response.raise_for_status() 
        
        # Return parsed JSON
        return response.json()
        
    except requests.exceptions.RequestException as e:
        # Catch any network errors or bad responses
        print(f"Ninjas Motorcycles API failed: {e}")
        return {"error": "Failed to fetch data from external API"}