---
name: mcp-servers
description: Model Context Protocol (MCP) server configuration, security vetting, and integration patterns for extending Claude Code with external tools and services.
---

# MCP Servers Skill

## When to Activate
- Configuring MCP servers for Claude Code
- Vetting third-party MCP servers for security
- Building custom MCP servers
- Integrating external services (databases, APIs, tools)

## What is MCP

Model Context Protocol (MCP) allows Claude Code to interact with external tools and services
through standardized server implementations. Servers provide tools that Claude can call
to read files, query databases, interact with APIs, etc.

## Configuration

### Project-level (`.claude/mcp.json`)
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/dbname"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### User-level (`~/.claude/mcp.json`)
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    }
  }
}
```

## Useful MCP Servers

| Server | Purpose | Package |
|--------|---------|---------|
| **filesystem** | Read/write files in allowed dirs | @modelcontextprotocol/server-filesystem |
| **postgres** | Query PostgreSQL databases | @modelcontextprotocol/server-postgres |
| **github** | GitHub API (repos, issues, PRs) | @modelcontextprotocol/server-github |
| **brave-search** | Web search | @anthropic/mcp-server-brave-search |
| **memory** | Persistent memory across sessions | @modelcontextprotocol/server-memory |
| **sqlite** | SQLite database operations | @modelcontextprotocol/server-sqlite |
| **context7** | Library documentation lookup | @context7/mcp-server |

## Security Vetting Checklist

Before adding any third-party MCP server:

1. **Source verification**
   - [ ] Is it from a known publisher (Anthropic, official repos)?
   - [ ] Check GitHub: stars, forks, recent activity, open issues
   - [ ] Review the source code (especially tool implementations)

2. **Permission analysis**
   - [ ] What filesystem paths does it access?
   - [ ] What network endpoints does it call?
   - [ ] Does it need write access? Why?
   - [ ] Does it require credentials? What for?

3. **Data exposure**
   - [ ] Does it send data to external servers?
   - [ ] Does it log sensitive information?
   - [ ] Can it exfiltrate environment variables?

4. **Principle of least privilege**
   - Only grant minimum required permissions
   - Use project-level config (not user-level) when possible
   - Restrict filesystem access to specific directories
   - Use read-only database connections where possible

## Building Custom MCP Server

```python
# Simple MCP server with Python
from mcp.server import Server
from mcp.types import Tool, TextContent

server = Server("my-custom-server")

@server.list_tools()
async def list_tools():
    return [
        Tool(
            name="query_pool_data",
            description="Query Uniswap pool data from local database",
            inputSchema={
                "type": "object",
                "properties": {
                    "pool_address": {"type": "string", "description": "Pool contract address"},
                    "chain": {"type": "string", "enum": ["ethereum", "bnb", "base"]},
                },
                "required": ["pool_address"],
            },
        ),
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "query_pool_data":
        data = await db.get_pool(arguments["pool_address"], arguments.get("chain", "ethereum"))
        return [TextContent(type="text", text=json.dumps(data))]

# Run server
if __name__ == "__main__":
    import asyncio
    from mcp.server.stdio import stdio_server
    asyncio.run(stdio_server(server))
```

Register in `.claude/mcp.json`:
```json
{
  "mcpServers": {
    "pool-data": {
      "command": "python",
      "args": ["scripts/mcp_pool_server.py"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

## Best Practices

- Keep MCP config in project-level `.claude/mcp.json` (version-controlled)
- Store secrets in environment variables, reference with `${VAR_NAME}`
- Use official Anthropic servers when possible
- Test MCP servers in development before production use
- Monitor MCP server resource usage (some can be memory-heavy)
- Document all MCP servers and their purpose in CLAUDE.md
