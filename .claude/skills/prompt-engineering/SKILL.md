---
name: prompt-engineering
description: Prompt engineering for LLM integration. Structured output, chain-of-thought, few-shot examples, and patterns for document processing, content generation, and data extraction.
---

# Prompt Engineering Skill

## When to Activate
- Integrating LLM APIs into applications
- Building document processing with AI
- Creating content generation pipelines
- Designing structured data extraction prompts
- Working with Anthropic Claude API or OpenAI API

## Core Principles

1. **Be specific** - vague prompts get vague results
2. **Provide structure** - define exact output format
3. **Give examples** - few-shot learning improves accuracy
4. **Set constraints** - limit output length, format, language
5. **Use system prompts** - set role and behavior boundaries

## Structured Output Pattern

```python
import anthropic
import json

client = anthropic.Anthropic()

def extract_structured(text: str, schema: dict) -> dict:
    """Extract structured data according to schema."""
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=2000,
        system="You are a data extraction assistant. Always return valid JSON matching the provided schema. No explanations, just JSON.",
        messages=[{
            "role": "user",
            "content": f"""Extract data from the following text according to this schema:

Schema:
{json.dumps(schema, indent=2)}

Text:
{text}

Return ONLY valid JSON. No markdown, no explanations."""
        }],
    )
    return json.loads(response.content[0].text)
```

## Prompt Templates by Task

### Document Data Extraction
```python
INVOICE_EXTRACTION_PROMPT = """You are an expert document processor. Extract all data from this invoice.

Rules:
- Return ONLY valid JSON
- Use null for missing fields
- Dates in YYYY-MM-DD format
- Amounts as numbers (not strings)
- Currency as ISO 4217 code (USD, EUR, UAH, etc.)

Required fields:
{schema}

Document text:
{document_text}"""
```

### Content Generation (Social Media)
```python
CONTENT_GENERATION_PROMPT = """You are a social media content creator for {niche}.

Task: Generate {count} posts for {platform}.

Requirements:
- Tone: {tone} (professional/casual/educational/entertaining)
- Language: {language}
- Max length: {max_length} characters
- Include relevant hashtags
- Each post must be unique and engaging
- Do NOT use generic filler phrases

Source material:
{source_content}

Return JSON array: [{{"text": "...", "hashtags": ["..."], "media_suggestion": "..."}}]"""
```

### Translation with Context
```python
TRANSLATION_PROMPT = """Translate the following {source_lang} text to {target_lang}.

Context: This is a {document_type} from a {industry} company.

Rules:
- Preserve formatting and structure
- Keep proper nouns unchanged
- Use industry-standard terminology in {target_lang}
- Preserve numbers, dates, and amounts exactly

Text:
{text}"""
```

### Code Review Prompt
```python
CODE_REVIEW_PROMPT = """Review this {language} code for:
1. Security vulnerabilities (OWASP Top 10)
2. Performance issues
3. Code quality and readability
4. Error handling completeness

Rate each issue: CRITICAL / HIGH / MEDIUM / LOW

Code:
```{language}
{code}
```

Return JSON: [{{"severity": "...", "line": N, "issue": "...", "suggestion": "..."}}]"""
```

## API Integration Patterns

### Anthropic Claude
```python
import anthropic

client = anthropic.Anthropic()  # Uses ANTHROPIC_API_KEY env var

# Simple message
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello"}],
)

# With system prompt and streaming
with client.messages.stream(
    model="claude-sonnet-4-20250514",
    max_tokens=2000,
    system="You are a helpful assistant.",
    messages=[{"role": "user", "content": prompt}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)

# Vision (image analysis)
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": base64_data}},
            {"type": "text", "text": "Describe this document"},
        ],
    }],
)
```

### Batch Processing
```python
async def process_batch(items: list[str], prompt_template: str, batch_size: int = 5) -> list[dict]:
    """Process items in batches to respect rate limits."""
    results = []
    for i in range(0, len(items), batch_size):
        batch = items[i:i + batch_size]
        tasks = [process_single(item, prompt_template) for item in batch]
        batch_results = await asyncio.gather(*tasks, return_exceptions=True)
        results.extend([r for r in batch_results if not isinstance(r, Exception)])
        await asyncio.sleep(1)  # Rate limit respect
    return results
```

## Model Selection Guide

| Task | Recommended Model | Why |
|------|-------------------|-----|
| Complex reasoning, coding | claude-opus-4-6 | Best quality |
| General tasks, good balance | claude-sonnet-4-6 | Speed + quality |
| Simple extraction, classification | claude-haiku-4-5 | Fastest, cheapest |
| Document processing | claude-sonnet-4-6 + vision | Good accuracy + vision |
| Content generation | claude-sonnet-4-6 | Creative + fast |

## Cost Optimization

- Use Haiku for simple tasks (classification, extraction)
- Use Sonnet for most production workloads
- Reserve Opus for complex reasoning and coding
- Cache responses for identical inputs
- Batch similar requests
- Set appropriate max_tokens (don't over-allocate)
- Use streaming for long responses (faster perceived latency)
