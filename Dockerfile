# Use the official Python 3.9 image
FROM python:3.9

# Hugging Face security requirement: Run as a non-root user
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"

# Set the working directory
WORKDIR /app

# Copy the requirements from your root folder and install
COPY --chown=user ./requirements.txt requirements.txt
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Copy backend folder into container
COPY --chown=user ./backend /app/backend

# Move inside the backend folder containing main.py
WORKDIR /app/backend

# Run the server on HF's mandatory port 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]