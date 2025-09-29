**# Shop API**

**A** **tiny** **FastAPI** **service** **with** **liveness**/**readiness** **endpoints** **and** **an** **in**-**memory** **store—perfect** **for** **ECS** **blue**/**green** **and** **health** **checks**.

**## Run locally**

```**bash**

python -**m** venv .**venv** && **source** .**venv**/**bin**/**activate**

pip install -**e** .[**dev**]

uvicorn src.**main**:**app** --**reload** --**port** **8080**

```

**## Test**

```**bash**

**pytest**

```

**## Build & run Docker**

```**bash**

**docker** **build** -**t** **shop**-**api**:**dev** ./**app**

**docker** **run** -**p** **8080**:**8080** -**e** **APP_VERSION**=**dev** -**e** **GIT_SHA**=$(**git** rev-**parse** --**short** HEAD) **shop**-**api**:**dev**

```

**## Endpoints**

- `**GET** /` **version** + **status**
- `**GET** /**healthz**/**live**` **liveness**
- `**GET** /**healthz**/**ready**` **readiness**
- `**GET** /**items**` **list**
- `**POST** /**items**` **create**
- `**GET** /**items**/{**id**}` **fetch**
- `**DELETE** /**items**/{**id**}` **delete**
