#!/usr/bin/env python3
"""
本地测试脚本 - 测试 RunPod ComfyUI Worker API
"""
import requests
import json
import sys
from pathlib import Path

# API 端点
API_URL = "http://localhost:8000/runsync"

def test_local_api(test_file="test_input copy 4.json"):
    """
    测试本地 API
    
    Args:
        test_file: 测试输入 JSON 文件路径
    """
    # 读取测试文件
    test_file_path = Path(test_file)
    if not test_file_path.exists():
        print(f"❌ 错误: 测试文件不存在: {test_file}")
        sys.exit(1)
    
    print(f"📄 读取测试文件: {test_file}")
    with open(test_file_path, 'r', encoding='utf-8') as f:
        test_input = json.load(f)
    
    print(f"\n🚀 发送请求到: {API_URL}")
    print(f"📦 测试输入包含:")
    print(f"   - 图片数量: {len(test_input.get('input', {}).get('images', []))}")
    print(f"   - 工作流节点数: {len(test_input.get('input', {}).get('workflow', {}))}")
    
    try:
        # 发送请求
        response = requests.post(
            API_URL,
            json=test_input,
            timeout=600  # 10 分钟超时
        )
        
        print(f"\n✅ 响应状态码: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            # 检查输出
            if 'output' in result and 'images' in result['output']:
                images = result['output']['images']
                print(f"✅ 成功生成 {len(images)} 张图片:")
                for i, img in enumerate(images, 1):
                    print(f"   {i}. {img.get('filename', 'unknown')} ({img.get('type', 'unknown')})")
                    if img.get('type') == 'base64':
                        base64_len = len(img.get('data', ''))
                        print(f"      Base64 长度: {base64_len} 字符")
            
            # 检查错误
            if 'output' in result and 'errors' in result['output']:
                errors = result['output']['errors']
                if errors:
                    print(f"\n⚠️  警告/错误 ({len(errors)} 个):")
                    for error in errors:
                        print(f"   - {error}")
            
            # 保存完整响应到文件
            output_file = "test_output.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            print(f"\n💾 完整响应已保存到: {output_file}")
            
        else:
            print(f"❌ 请求失败: {response.status_code}")
            print(f"响应内容: {response.text}")
            sys.exit(1)
            
    except requests.exceptions.ConnectionError:
        print(f"❌ 错误: 无法连接到 {API_URL}")
        print("   请确保 Docker Compose 服务正在运行:")
        print("   docker-compose up")
        sys.exit(1)
    except requests.exceptions.Timeout:
        print(f"❌ 错误: 请求超时（超过 10 分钟）")
        print("   工作流可能需要更长时间，请检查服务日志")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 错误: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    # 可以使用命令行参数指定测试文件
    test_file = sys.argv[1] if len(sys.argv) > 1 else "test_input copy 4.json"
    test_local_api(test_file)

