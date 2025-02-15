from fastapi import FastAPI, WebSocket
import uvicorn
import base64
import asyncio
import logging
import string
import os
import requests
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import json
import re
import util_helper

# 로깅 설정
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI()
util_helper = util_helper.util_helper(logger)
external_ip = util_helper.get_public_ip()
os_type = util_helper.get_os()


# WebSocket 핸들러
@app.websocket("/health_check_all")
async def websocket_health_check_all(websocket: WebSocket):
	try:
		await websocket.accept()
		while True:
			try:
				message = await websocket.receive_text()
				encrypted_value = message
				res = util_helper.id_check(encrypted_value)
				if res == -1:
					message = '{\"status\":\"false\"}'
					await websocket.send_text(message)
					continue
				node_list = list(set(util_helper.get_installed_node()))

				#노드가 설치 안되었을 경우
				print(node_list)
				if node_list == ['']:
					data = {"IP": external_ip, "OS": os_type}
					json_data = json.dumps(data)
					await websocket.send_text(json_data)
					continue
				#노드가 설치되었을때 헬스 체크 스크립트 실행
				for node in node_list:
					if node == "":
						command = f"./script/health_check/{node}_health_check.sh "
						node = util_helper.get_management_script_node_name()
						if node == -1:
							continue
					script_name = f"./script/health_check/{node}_health_check.sh"
					version = util_helper.get_version(script_name)
					#옛날버전체크할꺼생각.
					await util_helper.health_check_command(websocket, node, "", external_ip)

			except Exception as e:
				print(e)
				break

	except Exception as e:
		print(f"WebSocket 연결 오류: {e}")
	finally:
		print(f"클라이언트 {websocket.client} 연결 종료")
		try:
			await websocket.close()
		except RuntimeError:
			print("WebSocket 이미 종료됨, 추가 종료 시도 생략")

# WebSocket 핸들러
@app.websocket("/health_check")
async def websocket_health_check(websocket: WebSocket):
	try:
		await websocket.accept()
		while True:
			try:
				message = await websocket.receive_text()
				encrypted_value, encrypted_command, encrypted_type, encrypted_version, encrypted_node, encrypted_file = message.split("|")
				res = util_helper.id_check(encrypted_value)
				if res == -1:
					await websocket.close()
					return
				
				decrypted_command, decrypted_node, decrypted_type, decrypted_version = util_helper.decrypt_aes_command([encrypted_command, encrypted_node, encrypted_type, encrypted_version])
				script_name = f"./script/health_check/{decrypted_node}_health_check.sh"
				version = util_helper.get_version(script_name)
				if version != decrypted_version:
					await util_helper.run_command_async(decrypted_command)
				await util_helper.health_check_command(websocket, decrypted_node, decrypted_type, external_ip)

			except Exception as e:
				print(e)
				break

	except Exception as e:
		print(f"WebSocket 연결 오류: {e}")
	finally:
		print(f"클라이언트 {websocket.client} 연결 종료")
		try:
			await websocket.close()
		except RuntimeError:
			print("WebSocket 이미 종료됨, 추가 종료 시도 생략")

# WebSocket 핸들러
@app.websocket("/management")
async def websocket_endpoint(websocket: WebSocket):
	try:
		await websocket.accept()
		logger.info(f"클라이언트 연결됨: {websocket.client}")

		while True:
			try:
				message = await websocket.receive_text()       
				encrypted_value, encrypted_command, encrypted_type, encrypted_version, encrypted_node, encrypted_file = message.split("|")

				res = util_helper.id_check(encrypted_value)
				if res == -1:
					await websocket.close()
					return
								
				decrypted_command, manage_type, decrypted_version, decrypted_node, decrypted_file = util_helper.decrypt_aes_command([encrypted_command, encrypted_type, encrypted_version, encrypted_node, encrypted_file])

				res = util_helper.get_management_script_arg(decrypted_node)
				print(f"[+] res: {res}")
				if res != -1:
					data = {"IP": external_ip, "Nodes":{decrypted_node:{"status":-1, "latest_step":4, "all_step":4, "messages":"Already in progress."}}}
					json_data = json.dumps(data)
					print(f"[+] json_data: {json_data}")
					await websocket.send_text("stop")
					await websocket.close()
    
    
				script_name = f"./script/nodes/{decrypted_node}/management.sh"
				version = util_helper.get_version(script_name)

				if(manage_type == "install" and decrypted_node in util_helper.get_installed_node() and version == decrypted_version):
					data = {"IP": external_ip, "Nodes":{decrypted_node:{"status":1, "latest_step":4, "all_step":4, "messages":"installed"}}}
					json_data = json.dumps(data)
					await websocket.send_text(json_data)
					await websocket.close()
				else:
					if version != decrypted_version:
						await util_helper.run_command_async(decrypted_command)
					else:
						await util_helper.run_command_async(f"{script_name} {manage_type}")
					logger.info(f"확인할 파일: {decrypted_file}")
					await util_helper.check_file(websocket, decrypted_file, decrypted_node, manage_type)

			except Exception as e:
				logger.error(f"WebSocket 메시지 처리 중 오류 발생: {e}")
				break

	except Exception as e:
		logger.error(f"WebSocket 연결 오류: {e}")
	finally:
		logger.info(f"클라이언트 {websocket.client} 연결 종료")
		try:
			await websocket.close()
		except RuntimeError:
			logger.warning("WebSocket 이미 종료됨, 추가 종료 시도 생략")

# 서버 실행 함수
def run():
	logger.info("서버 시작")
	uvicorn.run(app, host="0.0.0.0", port=9000, log_level="info")


if __name__ == "__main__":
	run()
