from celery import Celery
from celery.schedules import crontab
from app.core.config import settings

celery_app = Celery(
    "leilao_inteligente",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.tasks.coleta_task", "app.tasks.alerta_task"],
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="America/Maceio",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

celery_app.conf.beat_schedule = {
    # Coleta diária às 6h
    "coleta-diaria": {
        "task": "app.tasks.coleta_task.executar_coleta_completa",
        "schedule": crontab(hour=6, minute=0),
        "args": ("all",),
    },
    # Verifica alertas a cada 30 minutos
    "verificar-alertas": {
        "task": "app.tasks.alerta_task.verificar_e_disparar_alertas",
        "schedule": crontab(minute="*/30"),
    },
    # Re-calcula scores às 7h
    "recalcular-scores": {
        "task": "app.tasks.coleta_task.recalcular_todos_scores",
        "schedule": crontab(hour=7, minute=0),
    },
}
