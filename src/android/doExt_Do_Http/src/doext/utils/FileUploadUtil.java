package doext.utils;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.UUID;

import core.DoServiceContainer;

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
	}

	/**
	 * android上传文件到服务器
	 * @param file 需要上传的文件
	 * @param RequestURL 请求的rul
	 * @return 返回响应的内容
	 */
	public String uploadFile(File file, String RequestURL) {
		String result = null;
		String BOUNDARY = UUID.randomUUID().toString(); // 边界标识 随机生成
		String PREFIX = "--", LINE_END = "\r\n";
		String CONTENT_TYPE = "multipart/form-data"; // 内容类型

		try {
			URL url = new URL(RequestURL);
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setReadTimeout(timeOut);
			conn.setConnectTimeout(timeOut);
			conn.setDoInput(true); // 允许输入流
			conn.setDoOutput(true); // 允许输出流
			conn.setUseCaches(false); // 不允许使用缓存
			conn.setRequestMethod("POST"); // 请求方式
			conn.setRequestProperty("Charset", CHARSET); // 设置编码
			conn.setRequestProperty("connection", "keep-alive");
			conn.setRequestProperty("Content-Type", CONTENT_TYPE + ";boundary=" + BOUNDARY);

			if (file != null) {
				/**
				 * 当文件不为空，把文件包装并且上传
				 */
				DataOutputStream dos = new DataOutputStream(conn.getOutputStream());
				StringBuffer sb = new StringBuffer();
				sb.append(PREFIX);
				sb.append(BOUNDARY);
				sb.append(LINE_END);
				/**
				 * 这里重点注意： name里面的值为服务器端需要key 只有这个key 才可以得到对应的文件
				 * filename是文件的名字，包含后缀名的 比如:abc.png
				 */

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
				 * 获取响应码 200=成功 当响应成功，获取响应的流
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
				}
			}
		} catch (MalformedURLException e) {
			e.printStackTrace();
			DoServiceContainer.getLogEngine().writeError("Http", e);
		} catch (IOException e) {
			e.printStackTrace();
			DoServiceContainer.getLogEngine().writeError("Http", e);
		}
		return result;
	}
}
