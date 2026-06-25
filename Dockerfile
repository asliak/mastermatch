# Use a standard slim Python base image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# Store the cached ML model inside the container directory
ENV SENTENCE_TRANSFORMERS_HOME=/app/model_cache
# Limit thread count for PyTorch / NumPy to keep memory usage minimal under 512MB
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV OPENBLAS_NUM_THREADS=1
ENV VECLIB_MAXIMUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1

# Set the working directory
WORKDIR /app

# Install system build dependencies (essential for compiling C-based packages like numpy/scikit-learn if wheels are not cached)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file first to optimize Docker layer caching
COPY requirements.txt /app/

# Install CPU-only PyTorch to reduce image size and build times (saves ~500MB)
RUN pip install --default-timeout=1000 --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# Install python dependencies
RUN pip install --default-timeout=1000 --no-cache-dir -r requirements.txt

# Pre-download and cache the SentenceTransformer model during build.
# This prevents downloading it on container startup, making boot times instant.
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

# Copy the rest of the application files
COPY . /app/

# Create a dedicated directory for the SQLite database (to mount a persistent volume in production)
RUN mkdir -p /app/data

# Collect static files into STATIC_ROOT using Whitenoise
RUN python manage.py collectstatic --noinput

# Expose port 8000
EXPOSE 8000

# Start server using gunicorn WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--timeout", "300", "mastermatch_django.wsgi:application"]
