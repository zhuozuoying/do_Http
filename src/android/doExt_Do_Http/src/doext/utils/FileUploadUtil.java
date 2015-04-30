package doext.utils;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.UUID;

public class FileUploadUtil {

	private int timeOut = 600000;
	private String CHARSET = "gbk";

	private int transferred; //上传进度

	private FileUploadListener listener;

	public FileUploadUtil(int timeOut) {
		this.timeOut = timeOut;
	}

	public void setListener(FileUploadListener listener) {
		this.listener = listener;
	}

	public interface FileUploadListener {
		void transferred(long count, long current);
		void onSuccess(String result);
		void onFailure(int statusCode,String msg);
	}

	/**
	 * android上传文件到服务器
	 * @param file 需要上传的文件
	 * @param RequestURL 请求的url
	 * @return 返回响应的内容
	 * @throws Exception 
	 */
	public String uploadFile(File file, String RequestURL) throws Exception {
		String result = null;
		String BOUNDARY = UUID.randomUUID().toString(); // 边界标识 随机生成
		String PREFIX = "--", LINE_END = "\r\n";
		String CONTENT_TYPE = "multipart/form-data"; // 内容类型
		HttpURLConnection conn = null;
		try {
			URL url = new URL(RequestURL);
			conn = (HttpURLConnection) url.openConnection();
			conn.setReadTimeout(timeOut);
			conn.setConnectTimeout(timeOut);
			conn.setDoInput(true); // 允许输入流
			conn.setDoOutput(true); // 允许输出流
			conn.setUseCaches(false); // 不允许使用缓存
			conn.setRequestMethod("POST"); // 请求方式
			conn.setRequestProperty("Charset", CHARSET); // 设置编码
			conn.setRequestProperty("connection", "keep-alive");
			conn.setRequestProperty("Content-Type", CONTENT_TYPE + ";boundary=" + BOUNDARY);
			conn.connect();//连接服务器
			if (file != null) {
				DataOutputStream dos = new DataOutputStream(conn.getOutputStream());
				StringBuffer sb = new StringBuffer();
				sb.append(PREFIX);
				sb.append(BOUNDARY);
				sb.append(LINE_END);
				sb.append("Content-Disposition: form-data; filename=\"" + file.getName() + "\"" + LINE_END);
				sb.append("Content-Type: application/octet-stream; charset=" + CHARSET + LINE_END);
				sb.append(LINE_END);
				dos.write(sb.toString().getBytes());
				InputStream is = new FileInputStream(file);
				byte[] bytes = new byte[4096];
				int len = 0;
				while ((len = is.read(bytes)) != -1) {
					dos.write(bytes, 0, len);
					if(this.listener != null){
						this.transferred += len;
						this.listener.transferred(file.length(), this.transferred);
					}
				}
				is.close();
				dos.write(LINE_END.getBytes());
				byte[] end_data = (PREFIX + BOUNDARY + PREFIX + LINE_END).getBytes();
				dos.write(end_data);
				dos.flush();
				/**
				 * 获取响应码 200=成功 当响应成功，//获取响应的流
				 */
				int res = conn.getResponseCode();
				if (res == 200) {
					BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), "utf-8"));
					String r = null;
					StringBuffer s = new StringBuffer();
					while ((r = reader.readLine()) != null) {
						s.append(r);
					}
					result = s.toString();
					this.listener.onSuccess(result);
				}
			}
		}  catch (IOException e) {
			this.listener.onFailure(conn.getResponseCode(), e.getMessage());
			e.printStackTrace();
		} finally {
			if(null != conn){
				conn.disconnect();//释放连接资源
			}
		}
		return result;
	}
}
