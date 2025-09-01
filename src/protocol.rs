use anyhow::{Context, Result};
use std::str;
use tracing::{debug, warn};

/// Redis 协议解析器，用于解析 RESP (Redis Serialization Protocol) 格式的命令
#[derive(Debug)]
pub struct RedisProtocolParser {
    buffer: Vec<u8>,
}

#[derive(Debug, Clone)]
pub enum RedisCommand {
    Auth { args: Vec<String> },
    Other { raw_data: Vec<u8> },
}

impl RedisProtocolParser {
    pub fn new() -> Self {
        Self {
            buffer: Vec::new(),
        }
    }

    /// 添加数据到缓冲区并尝试解析命令
    pub fn feed_data(&mut self, data: &[u8]) -> Result<Vec<RedisCommand>> {
        self.buffer.extend_from_slice(data);
        self.parse_commands()
    }

    /// 解析缓冲区中的命令
    fn parse_commands(&mut self) -> Result<Vec<RedisCommand>> {
        let mut commands = Vec::new();
        let mut pos = 0;

        while pos < self.buffer.len() {
            match self.try_parse_command_at(pos) {
                Ok(Some((command, consumed))) => {
                    commands.push(command);
                    pos += consumed;
                }
                Ok(None) => {
                    // 数据不完整，等待更多数据
                    break;
                }
                Err(e) => {
                    warn!("Failed to parse Redis command: {}", e);
                    // 跳过无效数据
                    pos += 1;
                }
            }
        }

        // 移除已处理的数据
        if pos > 0 {
            self.buffer.drain(0..pos);
        }

        Ok(commands)
    }

    /// 尝试在指定位置解析一个命令
    fn try_parse_command_at(&self, start: usize) -> Result<Option<(RedisCommand, usize)>> {
        if start >= self.buffer.len() {
            return Ok(None);
        }

        let data = &self.buffer[start..];
        
        // RESP 协议以 * 开头表示数组
        if data[0] == b'*' {
            self.parse_array_command(data)
        } else {
            // 处理其他格式的命令（如内联命令）
            self.parse_inline_command(data)
        }
    }

    /// 解析数组格式的命令 (*2\r\n$4\r\nAUTH\r\n$8\r\npassword\r\n)
    fn parse_array_command(&self, data: &[u8]) -> Result<Option<(RedisCommand, usize)>> {
        let mut pos = 1; // 跳过 '*'
        let start_pos = 0; // 记录命令开始位置（包括 '*'）

        // 读取数组长度
        let (array_len, consumed) = self.read_integer(data, pos)?;
        if array_len.is_none() {
            return Ok(None); // 数据不完整
        }
        let array_len = array_len.unwrap() as usize;
        pos += consumed;

        let mut args = Vec::new();

        // 解析每个参数
        for _ in 0..array_len {
            if pos >= data.len() {
                return Ok(None); // 数据不完整
            }

            if data[pos] != b'$' {
                return Err(anyhow::anyhow!("Expected bulk string marker '$'"));
            }
            pos += 1;

            // 读取字符串长度
            let (str_len, consumed) = self.read_integer(data, pos)?;
            if str_len.is_none() {
                return Ok(None); // 数据不完整
            }
            let str_len = str_len.unwrap() as usize;
            pos += consumed;

            // 读取字符串内容
            if pos + str_len + 2 > data.len() {
                return Ok(None); // 数据不完整
            }

            let arg_bytes = &data[pos..pos + str_len];
            let arg = String::from_utf8_lossy(arg_bytes).to_string();
            args.push(arg);
            pos += str_len + 2; // +2 for \r\n
        }

        // 检查是否是 AUTH 命令
        let command = if !args.is_empty() && args[0].to_uppercase() == "AUTH" {
            debug!("Detected AUTH command with {} arguments", args.len());
            RedisCommand::Auth { args }
        } else {
            // 对于非 AUTH 命令，返回原始数据
            let raw_data = data[start_pos..pos].to_vec();
            RedisCommand::Other { raw_data }
        };

        Ok(Some((command, pos)))
    }

    /// 解析内联命令格式 (AUTH password\r\n)
    fn parse_inline_command(&self, data: &[u8]) -> Result<Option<(RedisCommand, usize)>> {
        // 查找行结束符
        let line_end = data.windows(2).position(|w| w == b"\r\n");
        if line_end.is_none() {
            return Ok(None); // 数据不完整
        }
        let line_end = line_end.unwrap();

        let line = &data[..line_end];
        let line_str = str::from_utf8(line)
            .context("Invalid UTF-8 in inline command")?;

        let parts: Vec<&str> = line_str.split_whitespace().collect();
        if parts.is_empty() {
            return Ok(None);
        }

        let command = if parts[0].to_uppercase() == "AUTH" {
            let args: Vec<String> = parts.iter().map(|s| s.to_string()).collect();
            debug!("Detected inline AUTH command with {} arguments", args.len());
            RedisCommand::Auth { args }
        } else {
            let raw_data = data[..line_end + 2].to_vec(); // +2 for \r\n
            RedisCommand::Other { raw_data }
        };

        Ok(Some((command, line_end + 2)))
    }

    /// 读取整数值（直到 \r\n）
    fn read_integer(&self, data: &[u8], start: usize) -> Result<(Option<i64>, usize)> {
        let mut pos = start;
        let mut num_str = String::new();

        while pos < data.len() {
            if data[pos] == b'\r' {
                if pos + 1 < data.len() && data[pos + 1] == b'\n' {
                    // 找到完整的数字
                    let num = num_str.parse::<i64>()
                        .context("Invalid integer in Redis protocol")?;
                    return Ok((Some(num), pos - start + 2)); // +2 for \r\n
                } else {
                    return Ok((None, 0)); // 数据不完整
                }
            }
            num_str.push(data[pos] as char);
            pos += 1;
        }

        Ok((None, 0)) // 数据不完整
    }

    /// 清空缓冲区
    pub fn clear(&mut self) {
        self.buffer.clear();
    }
}

impl Default for RedisProtocolParser {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_auth_array_command() {
        let mut parser = RedisProtocolParser::new();
        
        // *2\r\n$4\r\nAUTH\r\n$8\r\npassword\r\n
        let data = b"*2\r\n$4\r\nAUTH\r\n$8\r\npassword\r\n";
        let commands = parser.feed_data(data).unwrap();
        
        assert_eq!(commands.len(), 1);
        match &commands[0] {
            RedisCommand::Auth { args } => {
                assert_eq!(args.len(), 2);
                assert_eq!(args[0], "AUTH");
                assert_eq!(args[1], "password");
            }
            _ => panic!("Expected AUTH command"),
        }
    }

    #[test]
    fn test_parse_auth_inline_command() {
        let mut parser = RedisProtocolParser::new();
        
        let data = b"AUTH password\r\n";
        let commands = parser.feed_data(data).unwrap();
        
        assert_eq!(commands.len(), 1);
        match &commands[0] {
            RedisCommand::Auth { args } => {
                assert_eq!(args.len(), 2);
                assert_eq!(args[0], "AUTH");
                assert_eq!(args[1], "password");
            }
            _ => panic!("Expected AUTH command"),
        }
    }

    #[test]
    fn test_parse_non_auth_command() {
        let mut parser = RedisProtocolParser::new();
        
        // *2\r\n$3\r\nGET\r\n$3\r\nkey\r\n
        let data = b"*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n";
        let commands = parser.feed_data(data).unwrap();
        
        assert_eq!(commands.len(), 1);
        match &commands[0] {
            RedisCommand::Other { raw_data } => {
                assert_eq!(raw_data, data);
            }
            _ => panic!("Expected Other command"),
        }
    }
}
