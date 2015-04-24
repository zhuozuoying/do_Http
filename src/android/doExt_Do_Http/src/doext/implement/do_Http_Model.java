package doext.implement;

import java.io.File;
import java.io.IOException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import net.tsz.afinal.FinalHttp;
import net.tsz.afinal.http.AjaxCallBack;

import org.apache.http.HttpResponse;
import org.apache.http.HttpVersion;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.params.ConnManagerParams;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.message.BasicHttpResponse;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.HTTP;
import org.apache.http.util.EntityUtils;

import core.DoServiceContainer;
import core.helper.DoIOHelper;
import core.helper.DoTextHelper;
import core.helper.jsonparse.DoJsonNode;
import core.helper.jsonparse.DoJsonValue;
import core.interfaces.DoIScriptEngine;
import core.interfaces.datamodel.DoIDataSource;
import core.object.DoInvokeResult;
import doext.define.do_Http_IMethod;
import doext.define.do_Http_MAbstract;
import doext.utils.FileUploadUtil;
import doext.utils.FileUploadUtil.FileUploadListener;

/**
 * 自定义扩展SM组件Model实现，继承Do_Http_MAbstract抽象类，并实现Do_Http_IMethod接口方法；
 * #如何调用组件自定义事件？可以通过如下方法触发事件：
 * this.model.getEventCenter().fireEvent(_messageName, jsonResult);
 * 参数解释：@_messageName字符串事件名称，@jsonResult传递事件参数对象； 获取DoInvokeResult对象方式new
 * DoInvokeResult(this.model.getUniqueKey());
 */
public class do_Http_Model extends do_Http_MAbstract implements do_Http_IMethod, DoIDataSource {

	public do_Http_Model() throws Exception {
		super();
	}

	/**
	 * 同步方法，JS脚本调用该组件对象方法时会被调用，可以根据_methodName调用相应的接口实现方法；
	 * 
	 * @_methodName 方法名称
	 * @_dictParas 参数（K,V）
	 * @_scriptEngine 当前Page JS上下文环境对象
	 * @_invokeResult 用于返回方法结果对象
	 */
	@Override
	public boolean invokeSyncMethod(String _methodName, DoJsonNode _dictParas, DoIScriptEngine _scriptEngine, DoInvokeResult _invokeResult) throws Exception {
		if ("request".equals(_methodName)) {
			request(_dictParas, _scriptEngine, _invokeResult);
			return true;
		}
		// ...do something
		return super.invokeSyncMethod(_methodName, _dictParas, _scriptEngine, _invokeResult);
	}

	/**
	 * 异步方法（通常都处理些耗时操作，避免UI线程阻塞），JS脚本调用该组件对象方法时会被调用， 可以根据_methodName调用相应的接口实现方法；
	 * 
	 * @_methodName 方法名称
	 * @_dictParas 参数（K,V）
	 * @_scriptEngine 当前page JS上下文环境
	 * @_callbackFuncName 回调函数名 #如何执行异步方法回调？可以通过如下方法：
	 *                    _scriptEngine.callback(_callbackFuncName,
	 *                    _invokeResult);
	 *                    参数解释：@_callbackFuncName回调函数名，@_invokeResult传递回调函数参数对象；
	 *                    获取DoInvokeResult对象方式new
	 *                    DoInvokeResult(this.model.getUniqueKey());
	 */
	@Override
	public boolean invokeAsyncMethod(String _methodName, DoJsonNode _dictParas, DoIScriptEngine _scriptEngine, String _callbackFuncName) throws Exception {
		// ...do something
		return super.invokeAsyncMethod(_methodName, _dictParas, _scriptEngine, _callbackFuncName);
	}

	/**
	 * 请求；
	 * 
	 * @_dictParas 参数（K,V），可以通过此对象提供相关方法来获取参数值（Key：为参数名称）；
	 * @_scriptEngine 当前Page JS上下文环境对象
	 * @_invokeResult 用于返回方法结果对象
	 */
	@Override
	public void request(DoJsonNode _dictParas, DoIScriptEngine _scriptEngine, final DoInvokeResult _invokeResult) throws Exception {
		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					String responseContent = doRequest();
					_invokeResult.setResultText(responseContent);
					getEventCenter().fireEvent("response", _invokeResult);
				} catch (Exception e) {
					e.printStackTrace();
					DoServiceContainer.getLogEngine().writeError("Http Error!" + e.getMessage(), e);
				}
			}
		}).start();
	}
	
	

	private String doRequest() throws Exception {
		String method = getPropertyValue("method");
		if (null == method || "".equals(method)) {
			throw new RuntimeException("请求类型方式失败，method：" + method);
		}
		String url = getPropertyValue("url");
		if (null == url || "".equals(url)) {
			throw new RuntimeException("请求地址错误，url：" + url);
		}
		int timeout = DoTextHelper.strToInt(getPropertyValue("timeout"), 5000);
		if ("post".equalsIgnoreCase(method)) {
			String contentType = getPropertyValue("contentType");
			if (null == contentType || "".equals(contentType)) {
				contentType = "text/html";
			}
			String body = getPropertyValue("body");
			return doPost(url, body, contentType, timeout);
		} else if ("get".equalsIgnoreCase(method)) {
			return doGet(url, timeout);
		}
		throw new RuntimeException("请求类型方式失败，method：" + method);
	}

	public HttpClient getHttpClient(int timeOut) throws Exception {
		HttpClient httpClient = null;
		KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
		trustStore.load(null, null);
		SSLSocketFactory sf = new SSLSocketFactoryEx(trustStore);
		sf.setHostnameVerifier(SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);

		HttpParams params = new BasicHttpParams();
		HttpProtocolParams.setVersion(params, HttpVersion.HTTP_1_1);
		HttpProtocolParams.setContentCharset(params, HTTP.DEFAULT_CONTENT_CHARSET);
		HttpProtocolParams.setUseExpectContinue(params, true);

		ConnManagerParams.setTimeout(params, timeOut);
		HttpConnectionParams.setConnectionTimeout(params, timeOut);
		HttpConnectionParams.setSoTimeout(params, timeOut);
		SchemeRegistry schReg = new SchemeRegistry();
		schReg.register(new Scheme("http", PlainSocketFactory.getSocketFactory(), 80));
		schReg.register(new Scheme("https", sf, 443));
		httpClient = new DefaultHttpClient(new ThreadSafeClientConnManager(params, schReg), params);
		return httpClient;
	}

	private String doGet(String url, int timeout) throws Exception {
		HttpClient httpClient = getHttpClient(timeout);
		HttpGet get = new HttpGet(url);
		HttpResponse response = httpClient.execute(get);
		int statusCode = response.getStatusLine().getStatusCode();
		if (statusCode != 200) {
			throw new RuntimeException("Get请求服务器失败，statusCode：" + statusCode);
		}
		return EntityUtils.toString(response.getEntity(), "UTF-8");
	}

	private String doPost(String url, String body, String contentType, int timeout) throws Exception {
		HttpClient httpClient = getHttpClient(timeout);
		HttpPost post = new HttpPost(url);
		StringEntity se = new StringEntity(body, HTTP.UTF_8);
		se.setContentType(contentType);
		post.setEntity(se);
		BasicHttpResponse response = (BasicHttpResponse) httpClient.execute(post);
		int statusCode = response.getStatusLine().getStatusCode();
		if (statusCode != 200) {
			throw new RuntimeException("Post请求服务器失败，statusCode：" + statusCode);
		}
		return EntityUtils.toString(response.getEntity(), "utf-8");
	}

	class SSLSocketFactoryEx extends SSLSocketFactory {
		SSLContext sslContext = SSLContext.getInstance("TLS");

		public SSLSocketFactoryEx(KeyStore truststore) throws NoSuchAlgorithmException, KeyManagementException, KeyStoreException, UnrecoverableKeyException {
			super(truststore);
			sslContext.init(null, new TrustManager[] { new MyTrustManager() }, null);
		}

		@Override
		public Socket createSocket(Socket socket, String host, int port, boolean autoClose) throws IOException, UnknownHostException {
			return sslContext.getSocketFactory().createSocket(socket, host, port, autoClose);
		}

		@Override
		public Socket createSocket() throws IOException {
			return sslContext.getSocketFactory().createSocket();
		}
	}

	class MyTrustManager implements X509TrustManager {
		@Override
		public java.security.cert.X509Certificate[] getAcceptedIssuers() {
			return null;
		}

		@Override
		public void checkClientTrusted(java.security.cert.X509Certificate[] chain, String authType) throws java.security.cert.CertificateException {
		}

		@Override
		public void checkServerTrusted(java.security.cert.X509Certificate[] chain, String authType) throws java.security.cert.CertificateException {
		}
	}

	@Override
	public void getJsonData(final DoGetJsonCallBack _callback) {
		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					String _resultData = doRequest();
					if (_resultData != null) {
						DoJsonValue _jsonResultValue = new DoJsonValue();
						_jsonResultValue.loadDataFromText(_resultData);
						_callback.doGetJsonCallBack(_jsonResultValue);
					}
				} catch (Exception e) {
					e.printStackTrace();
					DoServiceContainer.getLogEngine().writeError("Http Error!" + e.getMessage(), e);
				}
			}
		}).start();

	}

	@Override
	public void upload(DoJsonNode _dictParas, DoIScriptEngine _scriptEngine,
			DoInvokeResult _invokeResult) throws Exception {
		String path = _dictParas.getOneText("path", "");
		String fileFullPath = DoIOHelper.getLocalFileFullPath(this.getCurrentPage().getCurrentApp(), path);
		final File file = new File(fileFullPath);
		if (file.exists()) {
			new Thread(new Runnable() {
				@Override
				public void run() {
					try {
						int timeout = DoTextHelper.strToInt(getPropertyValue("timeout"), 500000);
						String url = getPropertyValue("url");
						FileUploadUtil uploadUtil = new FileUploadUtil(timeout);
						uploadUtil.setListener(new FileUploadListener() {
							@Override
							public void transferred(long count, long current) {
								DoInvokeResult _invokeResult = new DoInvokeResult(getUniqueKey());
								DoJsonNode jsonNode = new DoJsonNode();
								jsonNode.setOneText("currentSize", current + "");
								jsonNode.setOneText("totalSize", count + "");
								getEventCenter().fireEvent("response", _invokeResult);
							}
						});
						uploadUtil.uploadFile(file, url);
					} catch (Exception e) {
						DoServiceContainer.getLogEngine().writeError("Http upload \n", e);
					}
				}
			}).start();
		} else {
			DoServiceContainer.getLogEngine().writeInfo("Http upload \n", path + " 文件不存在");
		}
	}

	@Override
	public void download(DoJsonNode _dictParas, DoIScriptEngine _scriptEngine,
			DoInvokeResult _invokeResult) throws Exception {
		String path = _dictParas.getOneText("path", "");
		String _savaRelPath = DoIOHelper.getLocalFileFullPath(this.getCurrentPage().getCurrentApp(), path);
		FinalHttp fh = new FinalHttp();
		String url = getPropertyValue("url");
		fh.download(url, _savaRelPath, false, new AjaxCallBack<File>() {
			@Override
			public void onSuccess(File t) {
				super.onSuccess(t);
			}

			@Override
			public void onLoading(long count, long current) {
				super.onLoading(count, current);
				try {
					DoInvokeResult _invokeResult = new DoInvokeResult(getUniqueKey());
					DoJsonNode jsonNode = new DoJsonNode();
					jsonNode.setOneText("currentSize", current + "");
					jsonNode.setOneText("totalSize", count + "");
					getEventCenter().fireEvent("response", _invokeResult);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}

			@Override
			public void onFailure(Throwable t, int errorNo, String strMsg) {
				super.onFailure(t, errorNo, strMsg);
				DoServiceContainer.getLogEngine().writeInfo("Http Download", "下载失败" + strMsg);
			}
		});
	}
}
