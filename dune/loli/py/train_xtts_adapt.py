from TTS.api import TTS
from TTS.tts.configs.xtts_config import XttsConfig
from TTS.tts.datasets import load_tts_samples
from TTS.tts.models.xtts import Xtts
from trainer import Trainer, TrainerArgs

DATASET_PATH = "dataset_clean"
META_FILE = f"{DATASET_PATH}/metadata.csv"
WAV_PATH = f"{DATASET_PATH}/wavs"

OUTPUT_PATH = "xtts_training"

config = XttsConfig()

config.output_path = OUTPUT_PATH
config.batch_size = 8
config.eval_batch_size = 4
config.num_loader_workers = 4

config.run_eval = True
config.test_delay_epochs = 10

config.epochs = 150
config.lr = 5e-5

config.freeze_text_encoder = True
config.freeze_decoder = False

config.datasets = [
    {
        "name": "myvoice",
        "meta_file_train": META_FILE,
        "path": DATASET_PATH
    }
]

train_samples, eval_samples = load_tts_samples(
    config.datasets
)

model = Xtts.init_from_config(config)

trainer = Trainer(
    TrainerArgs(),
    config,
    output_path=OUTPUT_PATH,
    model=model,
    train_samples=train_samples,
    eval_samples=eval_samples
)

trainer.fit()
