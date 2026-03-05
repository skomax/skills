---
name: document-processing
description: Document processing with LLM/AI for invoice recognition, OCR, data extraction, and integration with ERP/SAP/Google Sheets/1C/Bitrix systems.
---

# Document Processing Skill

## When to Activate
- Processing invoices, receipts, bills of lading (TTN)
- OCR and document recognition
- LLM-based data extraction from documents
- Integration with Google Sheets, 1C, Bitrix, SAP/ERP
- Multi-user document processing pipelines

## Architecture

```
User Upload -> OCR/Vision -> LLM Extraction -> Validation -> Export
                                                               |
                                              +-------+--------+--------+
                                              |       |        |        |
                                           Google   1C API   Bitrix   SAP
                                           Sheets            API      API
```

## Document Processing Pipeline

```python
from dataclasses import dataclass
from enum import Enum

class DocumentType(Enum):
    INVOICE = "invoice"
    RECEIPT = "receipt"
    BILL_OF_LADING = "bill_of_lading"  # TTN
    PURCHASE_ORDER = "purchase_order"
    CUSTOM = "custom"

@dataclass
class ExtractedData:
    document_type: DocumentType
    raw_text: str
    structured_data: dict       # Extracted fields
    confidence: float           # 0.0 - 1.0
    language: str               # Detected language
    needs_review: bool          # Flag for manual review

class DocumentProcessor:
    def __init__(self, llm_client, ocr_engine):
        self.llm = llm_client
        self.ocr = ocr_engine

    async def process(self, file_path: str, user_settings: UserSettings) -> ExtractedData:
        # Step 1: OCR / Vision extraction
        raw_text = await self.extract_text(file_path)

        # Step 2: LLM-based structured extraction
        structured = await self.extract_fields(raw_text, user_settings)

        # Step 3: Translation if needed
        if user_settings.translate_to:
            structured = await self.translate(structured, user_settings.translate_to)

        # Step 4: Validation
        validated = self.validate(structured)

        return validated
```

## LLM Extraction with Anthropic SDK

```python
import anthropic

class LLMExtractor:
    def __init__(self):
        self.client = anthropic.Anthropic()

    async def extract_invoice(self, text: str) -> dict:
        response = self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2000,
            messages=[{
                "role": "user",
                "content": f"""Extract structured data from this invoice.
Return JSON with these fields:
- invoice_number: string
- date: YYYY-MM-DD
- supplier_name: string
- supplier_tax_id: string
- buyer_name: string
- buyer_tax_id: string
- items: array of {{description, quantity, unit_price, total, vat_rate}}
- subtotal: number
- vat_amount: number
- total_amount: number
- currency: string

Invoice text:
{text}"""
            }],
        )
        return json.loads(response.content[0].text)

    async def extract_with_vision(self, image_path: str) -> dict:
        """Process document image directly with Claude Vision."""
        import base64
        with open(image_path, "rb") as f:
            image_data = base64.standard_b64encode(f.read()).decode("utf-8")

        response = self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2000,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": image_data}},
                    {"type": "text", "text": "Extract all data from this document. Return structured JSON."}
                ]
            }],
        )
        return json.loads(response.content[0].text)
```

## Export Integrations

### Google Sheets
```python
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

class GoogleSheetsExporter:
    def __init__(self, credentials_path: str):
        creds = Credentials.from_service_account_file(credentials_path)
        self.service = build("sheets", "v4", credentials=creds)

    async def export(self, data: ExtractedData, template_id: str, user_config: dict):
        """Export to user-specific Google Sheet template."""
        sheet_id = user_config["sheet_id"]
        sheet_range = user_config.get("range", "Sheet1!A1")
        field_mapping = user_config["field_mapping"]  # Maps extracted fields to columns

        values = self.map_to_template(data, field_mapping)

        self.service.spreadsheets().values().append(
            spreadsheetId=sheet_id,
            range=sheet_range,
            valueInputOption="USER_ENTERED",
            body={"values": [values]},
        ).execute()
```

### 1C Integration
```python
class OneCExporter:
    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url
        self.auth = (username, password)

    async def export_invoice(self, data: ExtractedData):
        """Export invoice to 1C via OData/REST."""
        payload = {
            "Number": data.structured_data["invoice_number"],
            "Date": data.structured_data["date"],
            "Contractor": data.structured_data["supplier_name"],
            "Amount": data.structured_data["total_amount"],
            "Items": [
                {"Description": item["description"], "Quantity": item["quantity"],
                 "Price": item["unit_price"], "Amount": item["total"]}
                for item in data.structured_data["items"]
            ],
        }
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/odata/standard.odata/Document_Invoice",
                json=payload, auth=self.auth,
            )
            response.raise_for_status()
```

### Bitrix24 Integration
```python
class Bitrix24Exporter:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url

    async def create_deal(self, data: ExtractedData):
        async with httpx.AsyncClient() as client:
            await client.post(
                f"{self.webhook_url}/crm.deal.add.json",
                json={"fields": {
                    "TITLE": f"Invoice {data.structured_data['invoice_number']}",
                    "OPPORTUNITY": data.structured_data["total_amount"],
                    "CURRENCY_ID": data.structured_data["currency"],
                }},
            )
```

## Multi-User Configuration

```python
@dataclass
class UserSettings:
    user_id: str
    translate_to: str | None = None        # Target language code
    export_type: str = "google_sheets"      # google_sheets | 1c | bitrix | sap
    export_config: dict = field(default_factory=dict)  # Per-user export settings
    store_in_db: bool = True                # Store extracted data in DB
    auto_approve: bool = False              # Skip manual review
    custom_fields: list[str] | None = None  # Additional fields to extract
```

## OCR Engine Selection

| Engine | Best For | Speed | Accuracy | Setup |
|--------|----------|-------|----------|-------|
| **Claude Vision** | Any document, handwritten | Fast | Highest | API key only |
| **Tesseract** | Printed text, free/local | Medium | Good | `apt install tesseract-ocr` |
| **EasyOCR** | Multi-language, GPU-accelerated | Medium | Good | `pip install easyocr` |
| **PaddleOCR** | Complex layouts, tables | Fast | Very Good | `pip install paddleocr` |

### Tesseract Integration
```python
import pytesseract
from PIL import Image

def ocr_tesseract(image_path: str, lang: str = "eng+ukr") -> str:
    """OCR with Tesseract. Install: apt install tesseract-ocr tesseract-ocr-ukr"""
    image = Image.open(image_path)
    text = pytesseract.image_to_string(image, lang=lang, config="--psm 6")
    return text.strip()

def ocr_to_hocr(image_path: str) -> str:
    """Get positional data (bounding boxes) for each word."""
    return pytesseract.image_to_pdf_or_hocr(image_path, extension="hocr")
```

### EasyOCR Integration
```python
import easyocr

def ocr_easyocr(image_path: str, languages: list[str] = ["en", "uk"]) -> str:
    reader = easyocr.Reader(languages, gpu=True)
    results = reader.readtext(image_path)
    return "\n".join([text for _, text, conf in results if conf > 0.5])
```

## PDF Processing

```python
import fitz  # PyMuPDF
import pdfplumber

# PyMuPDF - fast text extraction
def extract_pdf_text(pdf_path: str) -> str:
    doc = fitz.open(pdf_path)
    text = ""
    for page in doc:
        text += page.get_text()
    return text

# pdfplumber - table extraction
def extract_pdf_tables(pdf_path: str) -> list[list[list[str]]]:
    tables = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_tables = page.extract_tables()
            tables.extend(page_tables)
    return tables

# Combined: text + tables + images
async def process_pdf_complete(pdf_path: str, llm: LLMExtractor) -> ExtractedData:
    text = extract_pdf_text(pdf_path)
    tables = extract_pdf_tables(pdf_path)

    # If text extraction poor (scanned PDF), use OCR
    if len(text.strip()) < 50:
        doc = fitz.open(pdf_path)
        for page in doc:
            pix = page.get_pixmap(dpi=300)
            img_path = f"/tmp/page_{page.number}.png"
            pix.save(img_path)
            text += await llm.extract_with_vision(img_path)

    return await llm.extract_invoice(text + "\n\nTables:\n" + str(tables))
```

## SAP Integration via RFC
```python
# pip install pyrfc (requires SAP NW RFC SDK)
from pyrfc import Connection

class SAPExporter:
    def __init__(self, ashost: str, sysnr: str, client: str, user: str, passwd: str):
        self.conn_params = {
            "ashost": ashost, "sysnr": sysnr,
            "client": client, "user": user, "passwd": passwd,
        }

    def export_invoice(self, data: ExtractedData):
        with Connection(**self.conn_params) as conn:
            result = conn.call("BAPI_INCOMINGINVOICE_CREATE", {
                "HEADERDATA": {
                    "DOC_TYPE": "RE",
                    "COMP_CODE": "1000",
                    "DOC_DATE": data.structured_data["date"],
                    "REF_DOC_NO": data.structured_data["invoice_number"],
                    "GROSS_AMOUNT": data.structured_data["total_amount"],
                    "CURRENCY": data.structured_data["currency"],
                },
                "ITEMDATA": [
                    {"INVOICE_DOC_ITEM": str(i + 1).zfill(10),
                     "AMOUNT": item["total"],
                     "TAX_CODE": self._map_vat_code(item["vat_rate"])}
                    for i, item in enumerate(data.structured_data["items"])
                ],
            })
            if result.get("RETURN", [{}])[0].get("TYPE") == "E":
                raise Exception(f"SAP error: {result['RETURN'][0]['MESSAGE']}")
            return result
```

## Validation Rules Engine
```python
from dataclasses import dataclass

@dataclass
class ValidationRule:
    field: str
    rule_type: str   # required | format | range | cross_field
    params: dict

class DataValidator:
    RULES = {
        "invoice": [
            ValidationRule("invoice_number", "required", {}),
            ValidationRule("date", "format", {"pattern": r"\d{4}-\d{2}-\d{2}"}),
            ValidationRule("total_amount", "range", {"min": 0.01, "max": 99_999_999}),
            ValidationRule("total_amount", "cross_field", {
                "check": "equals_sum", "sum_field": "items.total",
            }),
            ValidationRule("vat_amount", "cross_field", {
                "check": "percentage_of", "base_field": "subtotal",
                "tolerance": 0.01,
            }),
        ],
    }

    def validate(self, data: ExtractedData) -> list[str]:
        errors = []
        rules = self.RULES.get(data.document_type.value, [])
        for rule in rules:
            value = data.structured_data.get(rule.field)
            if rule.rule_type == "required" and not value:
                errors.append(f"Missing required field: {rule.field}")
            elif rule.rule_type == "range":
                if value and not (rule.params["min"] <= value <= rule.params["max"]):
                    errors.append(f"{rule.field} out of range: {value}")
            elif rule.rule_type == "cross_field" and rule.params["check"] == "equals_sum":
                items_sum = sum(i.get("total", 0) for i in data.structured_data.get("items", []))
                if abs(value - items_sum) > 0.01:
                    errors.append(f"{rule.field} ({value}) != sum of items ({items_sum})")
        return errors
```

## Admin Panel Features

- User management (create, configure, deactivate)
- Per-user export template configuration
- Processing statistics and error logs
- Manual review queue for low-confidence extractions
- Custom field mapping editor
- API key management for external integrations
- Document processing history with search/filter
- Batch processing mode (upload ZIP with multiple documents)
- Webhook notifications on processing completion
