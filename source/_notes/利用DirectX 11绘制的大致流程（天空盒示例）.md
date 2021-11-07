---
title: 利用DirectX11绘制的大致示例（天空盒）
date: 2020-02-27 12:58:26
tags: 
---

参考：  

摘要：

![封面]()

<!--more -->


## 本文的主要内容
刚开始学习`DirectX 11`时，看了诸多的资料包括源码后，仍是一头雾水，花费了大量的时间不断地理解代码到底是如何作用于我想要的结果的。本文旨在记录和阐述各个代码在整个程序中扮演的角色。并以天空盒的实现作为了一个小小的例子。本人也是初学这部分内容，若有说的错误之处，还望指正。
[源码链接](https://download.csdn.net/download/wz2671/12194516)
***
### 一、准备知识  
想要能上手Direct3D，必然不能是零基础的，在开始学习之前，主要掌握或者了解以下知识：
* 渲染流水线的大致步骤。
* 空间几何，线性代数。

掌握上述知识后，就可以开始看别人的代码跟着学了。本文以天空盒的实现为例，大致勾画出一个完整的Direct3D程序应有的步骤。
至于天空盒，是利用立方体映射技术将一个贴着天空纹理的立方体映射到一个球面上，然后通过将天空盒的圆心位置和摄像机坐标同时移动形成天空效果。

效果图如下所示：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200225163738209.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3d6MjY3MQ==,size_16,color_FFFFFF,t_70)
***
### 二、项目创建和Direct3D初始化
**首先应当创建一个桌面应用**或者空项目但子系统指定为窗口（而不是控制台应用），之后只需要少量的Win32代码就可以创建出一个窗口，在处理消息的循环中，我们的程序会不断更新。更新的具体方法可以在`MsgProc`函数中进行定义。

在这个部分，需要关注的变量和函数有如下：  
* `MsgProc`函数和`MSG messages`变量，毋庸置疑，这部分决定了我们的操作带来什么样的效果。至于其中的更多细节，属于Win32编程中的内容，可参考《 windows 程序设计 第五版》一书。
* `HWND MainWnd`变量指的是该窗口的句柄，只有拥有该变量的值，我们才能够捕获窗口中的事件以及将场景几何体渲染到该窗口。

```cpp
LRESULT CALLBACK MsgProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE prevInstance,
	_In_ LPSTR cmdLine, _In_ int showCmd)
{
	// 这些参数不使用
	UNREFERENCED_PARAMETER(prevInstance);
	UNREFERENCED_PARAMETER(cmdLine);
	UNREFERENCED_PARAMETER(showCmd);

	WNDCLASS wc;
	wc.style = CS_HREDRAW | CS_VREDRAW;
	wc.lpfnWndProc = MsgProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = hInstance;
	wc.hIcon = LoadIcon(0, IDI_APPLICATION);
	wc.hCursor = LoadCursor(0, IDC_ARROW);
	wc.hbrBackground = (HBRUSH)GetStockObject(NULL_BRUSH);
	wc.lpszMenuName = 0;
	wc.lpszClassName = L"D3DWndClassName";
	int width = 800, height = 600;

	if (!RegisterClass(&wc))
	{
		MessageBox(0, L"RegisterClass Failed.", 0, 0);
		return false;
	}

	RECT R = { 0, 0, width, height };
	AdjustWindowRect(&R, WS_OVERLAPPEDWINDOW, false);

	HWND MainWnd = CreateWindow(L"D3DWndClassName", L"SkyBox",
		WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, width, height, 0, 0, hInstance, 0);
	if (!MainWnd)
	{
		MessageBox(0, L"CreateWindow Failed.", 0, 0);
		return false;
	}

	ShowWindow(MainWnd, SW_SHOW);
	UpdateWindow(MainWnd);
	MSG messages = { 0 };
	
	/* 在这部分就可以创建并初始化我们的Direct3D程序了*/
	
	//这儿会不断接受并处理消息
	while (messages.message != WM_QUIT)
	{
		if (PeekMessage(&messages, 0, 0, 0, PM_REMOVE))
		{ 
			TranslateMessage(&messages);
			DispatchMessage(&messages);
		}
		// 在这里处理消息并更新我们的应用程序
	}

	return messages.wParam;
}
```
**当窗口创建完毕，根据窗口的句柄即可以初始化Direct3D所需的资源**，这部分的代码相对变动较小，可以~~先抄了跑起来再说~~ 之后再细细研究。

初始化Direct3D（D3D）所需的步骤大致如下:

1. **定义想检查的设备类型和特征级别**，这部分也就是检查一下可用的设备（硬件设备，WARP设备，软件驱动设备之类），以及所支持的DirectX类型（D3D11.0，D3D10.1，D3D10.0等）。
	```cpp
	// 驱动类型数组
	D3D_DRIVER_TYPE driverTypes[] =
	{
		D3D_DRIVER_TYPE_HARDWARE,
		D3D_DRIVER_TYPE_WARP,
		D3D_DRIVER_TYPE_REFERENCE,
		D3D_DRIVER_TYPE_SOFTWARE,
	};
	// 特性等级数组
	D3D_FEATURE_LEVEL featureLevels[] =
	{
		D3D_FEATURE_LEVEL_11_1,
		D3D_FEATURE_LEVEL_11_0,
		D3D_FEATURE_LEVEL_10_1,
		D3D_FEATURE_LEVEL_10_0,
	};
	```
2. **创建D3D设备，上下文和交换链**，D3D设备(`ID3D11Device`)和上下文(`ID3D11DeviceContext`)是用于和硬件交互的接口，也是后续用到的==最多的东西==。交换链主要是用双缓冲技术保证画面稳定所用。D3D设备和D3D上下文的主要的功能分别为，D3D设备一般用于分配资源（例如创建缓冲区等），而D3D上下文用于将资源绑定到图形管线并产生渲染命令等。下段代码是对这三个创建的示意程序。
	```cpp
	D3D_FEATURE_LEVEL featureLevel;
	ID3D11Device * pd3dDevice;						// D3D设备
	ID3D11DeviceContext * pd3dImmediateContext;		// D3D上下文
	IDXGISwapChain * pSwapChain;					// D3D交换链
	// 在hr中可以得知是否创建成功，这个返回值在之后也会反复出现
	HRESULT hr = D3D11CreateDevice(0, D3D_DRIVER_TYPE_HARDWARE, 0, createDeviceFlags, 0, 0, 
			D3D11_SDK_VERSION, &d3dDevice, &featureLevel, &d3dImmediateContext);
	// 先对交换链描述结构体进行填充，再调用函数来创建交换链
	DXGI_SWAP_CHAIN_DESC swapChainDesc;							// 交换链描述
	// 填充swapChainDesc
	CreateSwapChain(pd3dDevice, &swapChainDesc, &pSwapChain) 	// 创建交换链
	```
	
3. **创建渲染目标视图**，渲染目标视图主要为了在交换链的辅助缓存（在后面绘画的缓冲区）中联合渲染。
	```cpp
	ID3D11RenderTargetView * pBackBufferTarget;		// 渲染目标视图
	ID3D11Texture2D * pBackBufferTexture;			// 贴图
	HRESULT result;
	// 获取辅助缓存的指针
	result = pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (LPVOID*)&pBackBufferTexture);
	// 创建渲染目标视图
	result = pd3dDevice->CreateRenderTargetView(pBackBufferTexture, 0, &pBackBufferTarget);
	if (pBackBufferTexture)
		pBackBufferTexture->Release();	// 释放交换链的后向缓存指针
	d3dContext->OMSetRenderTargets(1, &pBackBufferTarget, 0);	// 
	```
4. **设置视口观察区**，也就是要在屏幕上渲染的区域，单人游戏即为D3D交换链的宽高即可。设置方法为先填充`D3D11_VIEWPORT`结构体，再调用`RSSetViewports`函数即可。

***
### 三、创建几何体数据
在初始化完上述Direct3D之后，就可以着手准备我们想实现的效果了，如果渲染流程有了大致了解的话，那么就应该知道，我们现在只需要**准备顶点数据**和**设置渲染状态**即可，当这些做好之后，就可以调用`Draw`命令使GPU开始工作。

在该小节，就简要介绍一下创建顶点数据部分。既然是要绘制天空球，那么自然是应该创建一个球面，球面是由三角形面片来近似的，具体的创建方法也很简单，大体思路是从球面上采样取点，让一个个三角形拼成大致的球即可。在这里，主要是强调以下部分：
* 创建一个几何体，所需的只有两个部分，顶点的数据以及索引数据，可以采用`vector`容器存储。其中，顶点数据类型随绘制物体不同包含的内容也不同，在绘制天空球时，仅仅只需要位置`POSITION`信息，若是场景中的物体且有光照纹理等，一般还需要`NORMAL`法线向量，`TEXCOORD`纹理坐标等信息。
* 采用索引来表示三角面片，并且图元类型为三角形列表`SetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST)`时，那么应当采用逆时针的绘制方法，因为我们是从圆的内部往外部看。

准备好这些数据之后，就可以为渲染做准备了。创建几何体数据的步骤不一定非要在之前做，只需要在调用绘制命令之前，将所有东西准备好即可。创建球面的示意代码如下所示：
```cpp
struct VertexPos		// 顶点结构体
{
	VertexPos() = default;

	VertexPos(const VertexPos&) = default;
	VertexPos& operator=(const VertexPos&) = default;

	VertexPos(VertexPos&&) = default;
	VertexPos& operator=(VertexPos&&) = default;

	constexpr VertexPos(const DirectX::XMFLOAT3& _pos) : pos(_pos) {}

	DirectX::XMFLOAT3 pos;
	static const D3D11_INPUT_ELEMENT_DESC inputLayout[1];		// 这个部分在创建输入布局时所需
};

std::vector<VertexPos> vertexVector;		// 顶点数组
std::vector<UINT> indexVector;				// 索引数组

void CreateSphere(float radis, UINT levels, UINT slices)
{
	// 创建天空球的顶点数据和索引数据（逆时针绘制）
	UINT vertexCount = 2 + (levels - 1) * (slices + 1);
	UINT indexCount = 6 * (levels - 1) * slices;
	vertexVector.resize(vertexCount);
	indexVector.resize(indexCount);

	VertexPos vertexData;
	UINT vIndex = 0, iIndex = 0;

	float phi = 0.0f, theta = 0.0f;
	float per_phi = XM_PI / levels;
	float per_theta = XM_2PI / slices;
	float x, y, z;

	// 放入顶端点
	vertexData = {XMFLOAT3(0.0f, radius, 0.0f)};
	vertexVector[vIndex++] = vertexData;

	for (UINT i = 1; i < levels; ++i)
	{
		phi = per_phi * i;
		// 需要slices + 1个顶点是因为 起点和终点需为同一点，但纹理坐标值不一致
		for (UINT j = 0; j <= slices; ++j)
		{
			theta = per_theta * j;
			x = radius * sinf(phi) * cosf(theta);
			y = radius * cosf(phi);
			z = radius * sinf(phi) * sinf(theta);
			// 计算出局部坐标、法向量、Tangent向量和纹理坐标
			vertexVector[vIndex++] = { XMFLOAT3(x, y, z) };
		}
	}

	// 放入底端点
	vertexData = { XMFLOAT3(0.0f, -radius, 0.0f) };
	vertexVector[vIndex++] = vertexData;

	// 放入索引
	if (levels > 1)
	{
		for (UINT j = 1; j <= slices; ++j)
		{
			indexVector[iIndex++] = 0;
			indexVector[iIndex++] = j;
			indexVector[iIndex++] = j % (slices + 1) + 1;
		}
	}

	for (UINT i = 1; i < levels - 1; ++i)
	{
		for (UINT j = 1; j <= slices; ++j)
		{
			indexVector[iIndex++] = (i - 1) * (slices + 1) + j;
			indexVector[iIndex++] = i * (slices + 1) + j % (slices + 1) + 1;
			indexVector[iIndex++] = (i - 1) * (slices + 1) + j % (slices + 1) + 1;

			indexVector[iIndex++] = i * (slices + 1) + j % (slices + 1) + 1;
			indexVector[iIndex++] = (i - 1) * (slices + 1) + j;
			indexVector[iIndex++] = i * (slices + 1) + j;
		}
	}

	if (levels > 1)
	{
		for (UINT j = 1; j <= slices; ++j)
		{
			indexVector[iIndex++] = (levels - 2) * (slices + 1) + j;
			indexVector[iIndex++] = (levels - 1) * (slices + 1) + 1;
			indexVector[iIndex++] = (levels - 2) * (slices + 1) + j % (slices + 1) + 1;
		}
	}
}
```

***
### 四、设置渲染状态
这个部分的工作是最为繁杂的，各种特效的实现也是依赖于此，由于本文更关注于捋清整个代码工作流程，就一切从简，只引入相机部分了（不然看个🔨）。就算偷懒，要做的事情仍然不少，总体而言有如下几部分：  
* 加载和创建资源
* 设置渲染流水线状态
* 绑定渲染管线并绘制

接下来将对各个部分进行详细描述。
##### 1. 加载和创建资源
需要创建的资源有：
* **顶点缓冲区**
* **索引缓冲区**
* **纹理数据**

顶点缓冲区，索引缓冲区，纹理数据和之前创建的几何顶点数据是共同使用的，这三部份配合合适的渲染状态（顶点布局，着色器等）就可以绘制出令人满意的效果。
```cpp
ID3D11ShaderResourceView * pTextureCubeSRV;
// 顶点缓冲区创建
void CreateVertexBuffer(UINT byteWidth, const void *pInitialData, ID3D11Buffer ** pVB)
{
	// 顶点缓冲区描述
	D3D11_BUFFER_DESC vbd;
	ZeroMemory(&vbd, sizeof(vbd));
	vbd.Usage = D3D11_USAGE_IMMUTABLE;
	vbd.ByteWidth = byteWidth;
	vbd.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	vbd.CPUAccessFlags = 0;
	// 创建顶点缓冲区
	D3D11_SUBRESOURCE_DATA InitData;
	ZeroMemory(&InitData, sizeof(InitData));
	InitData.pSysMem = pInitialData;
	pd3dDevice->CreateBuffer(&vbd, &InitData, pVB);
}
// 索引缓冲区创建
void CreateIndexBuffer(UINT byteWidth, const void *pInitialData, ID3D11Buffer ** pIB)
{
	// 索引缓冲区描述
	D3D11_BUFFER_DESC ibd;
	ZeroMemory(&ibd, sizeof(ibd));
	ibd.Usage = D3D11_USAGE_IMMUTABLE;
	ibd.ByteWidth = byteWidth;	// 索引类型为UINT
	ibd.BindFlags = D3D11_BIND_INDEX_BUFFER;
	ibd.CPUAccessFlags = 0;
	// 创建索引缓冲区
	D3D11_SUBRESOURCE_DATA InitData;
	ZeroMemory(&InitData, sizeof(InitData));
	InitData.pSysMem = pInitialData;
	pd3dDevice->CreateBuffer(&ibd, &InitData, pIB);
}
// 天空盒纹理加载
CreateDDSTextureFromFile(pd3dDevice, nullptr, L"Texture\\desertcube.dds", nullptr, &pTextureCubeSRV);
```

* **深度模板状态**
深度模板状态是用来保证天空盒可以通过深度测试的。
```cpp
void CreateDepthStencilState(ID3D11DepthStencilState **ppDSS)
{
	D3D11_DEPTH_STENCIL_DESC dsDesc;		// 填充该描述即可
	// 允许使用深度值一致的像素进行替换的深度/模板状态
	// 该状态用于绘制天空盒，因为深度值为1.0时默认无法通过深度测试
	dsDesc.DepthEnable = true;
	dsDesc.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
	dsDesc.DepthFunc = D3D11_COMPARISON_LESS_EQUAL;

	dsDesc.StencilEnable = false;
	pd3dDevice->CreateDepthStencilState(&dsDesc, ppDSS);
}
```

* **顶点着色器**
* **顶点布局**
* **像素着色器**
着色器一般采用HLSL着色语言编写，它最终会被显卡驱动翻译成GPU可以理解的语言。在以下的函数中，`hlslFileName`形参对应的文件中中存储着HLSL着色器的代码，它会被编译成显卡驱动能理解的中间语言，在这儿将它输出至`*.cso`文件中，至于HLSL语言和C++如何对应互通，则是通过结构体和绑定的缓冲区来传递数据。
```cpp
HRESULT CreateShaderFromFile(const WCHAR* csoFileNameInOut, const WCHAR* hlslFileName, 
	LPCSTR entryPoint, LPCSTR shaderModel, ID3DBlob** ppBlobOut)
{
	HRESULT hr = S_OK;
	// 寻找是否有已经编译好的顶点着色器
	if (csoFileNameInOut && D3DReadFileToBlob(csoFileNameInOut, ppBlobOut) == S_OK)
	{
		return hr;
	}
	else
	{
		DWORD dwShaderFlags = D3DCOMPILE_ENABLE_STRICTNESS;
		ID3DBlob* errorBlob = nullptr;
		hr = D3DCompileFromFile(hlslFileName, nullptr, D3D_COMPILE_STANDARD_FILE_INCLUDE, entryPoint, shaderModel,
			dwShaderFlags, 0, ppBlobOut, &errorBlob);
		if (FAILED(hr))
		{
			if (errorBlob != nullptr)
			{
				OutputDebugStringA(reinterpret_cast<const char*>(errorBlob->GetBufferPointer()));
			}
			SAFE_RELEASE(errorBlob);
			return hr;
		}
		// 若指定了输出文件名，则将着色器二进制信息输出
		if (csoFileNameInOut)
		{
			return D3DWriteBlobToFile(*ppBlobOut, csoFileNameInOut, FALSE);
		}
	}
	return hr;
}

// 创建顶点着色器
ID3DBlob * blob;
void CreateVertexShader(ID3D11VertexShader ** pVertexShader, const WCHAR* csoFileName, const WCHAR* hlslFileName)
{
	CreateShaderFromFile(csoFileName, hlslFileName, "VS_3D", "vs_5_0", blob.ReleaseAndGetAddressOf());
	pd3dDevice->CreateVertexShader(blob->GetBufferPointer(), blob->GetBufferSize(), nullptr, pVertexShader);
}
// 创建顶点布局
void CreateInputLayout(ID3D11InputLayout ** pVertexLayout, const D3D11_INPUT_ELEMENT_DESC *pInputElementDescs, UINT NumElements)
{
	pd3dDevice->CreateInputLayout(pInputElementDescs, NumElements, blob->GetBufferPointer(), blob->GetBufferSize(), pVertexLayout);
}
// 创建像素着色器
void CreatePixelShader(ID3D11PixelShader ** pPixelShader, const WCHAR* csoFileName, const WCHAR* hlslFileName)
{
	CreateShaderFromFile(csoFileName, hlslFileName, "PS_3D", "ps_5_0", blob.ReleaseAndGetAddressOf());
	pd3dDevice->CreatePixelShader(blob->GetBufferPointer(), blob->GetBufferSize(), nullptr, pPixelShader);
}
```
* **常量缓冲区**
常量缓冲区是实现相机，光照，反射等效果所用到的重要部分。以相机为例，我们得知了相机的视角矩阵和投影矩阵之后，那么我们需要更新这两个矩阵对应的缓冲区，并将新的数据传进去，才能被着色器所用，绘制出新的画面。着色器和常量缓冲区决定了各个顶点画出来在什么位置，是什么样子，它们是一起作用的。
创建常量缓冲区的代码如下所示：
```cpp
// 创建缓冲区
void CreateConstBuffer(UINT byteWidth, ID3D11Buffer ** cb)
{
	// 常量缓冲区描述
	D3D11_BUFFER_DESC cbd;
	ZeroMemory(&cbd, sizeof(cbd));
	cbd.Usage = D3D11_USAGE_DYNAMIC;
	cbd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	cbd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	cbd.ByteWidth = byteWidth;
	pd3dDevice->CreateBuffer(&cbd, nullptr, cb);
}
```
##### 2. 设置渲染流水线状态
这部分也就是把上述初始化以及创建的资源绑定到渲染管线上，我们只需要调用对应的方法即可。需要注意的是，如果在绘制天空球之前采用的不是这些渲染资源，那么我们需要重新调用以下函数来设置渲染状态（资源创建只需要调用一次）。
```cpp
void SetRender(ID3D11DeviceContext * deviceContext)
{
	deviceContext->IASetInputLayout(m_pVertexPosLayout.Get());		// 设置输入布局
	deviceContext->VSSetShader(m_pSkyVS.Get(), nullptr, 0);			// 设置顶点着色器
	deviceContext->PSSetShader(m_pSkyPS.Get(), nullptr, 0);			// 设置像素着色器

	deviceContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);	// 设置图元类型

	deviceContext->GSSetShader(nullptr, nullptr, 0);
	//deviceContext->RSSetState(RenderStates::RSNoCull.Get());

	//deviceContext->PSSetSamplers(0, 1, RenderStates::SSLinearWrap.GetAddressOf());

	deviceContext->OMSetDepthStencilState(pDSSLessEqual.Get(), 0);		// 设置深度/模板状态
	deviceContext->OMSetBlendState(nullptr, nullptr, 0xFFFFFFFF);
}
```
##### 3. 绑定渲染管线并绘制
在这个部分，也就是要绘制我们的模型了，可想而知，也就是切换顶点缓冲区，索引缓冲区，纹理资源等，因为我们不可能就只画我们的天空球，而这些也是组成我们天空球的部分。除此之外，在本文还需要更新常量缓冲区的内容，具体细节，在后面会更详细叙述。以下代码中还有摄像机作为参数，因为天空球需要随摄像机移动也跟着移动，所需相机的位置也是需要知道的。
```cpp
void Draw(ID3D11DeviceContext * deviceContext, const WZCamera * camera)
{
	UINT strides = sizeof(VertexPos);
	UINT offsets = 0;
	deviceContext->IASetVertexBuffers(0, 1, &pVertexBuffer, &strides, &offsets);	// 设置顶点缓冲区
	deviceContext->IASetIndexBuffer(pIndexBuffer, DXGI_FORMAT_R32_UINT, 0);			// 设置索引缓冲区
	// 先在结构体变量中更新值
	XMFLOAT3 pos = camera->GetPosition();
	varCBSky.worldViewProj = XMMatrixTranspose(XMMatrixTranslation(pos.x, pos.y, pos.z) * (camera->GetViewProjXM()));
	// 再更新至对应的常量缓冲区中
	D3D11_MAPPED_SUBRESOURCE mappedData;
	deviceContext->Map(pCBSkyBuffer.Get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedData);
	memcpy_s(mappedData.pData, sizeof(varCBSky), &varCBSky, sizeof(varCBSky));
	deviceContext->Unmap(pCBSkyBuffer.Get(), 0);

	// 将缓冲区绑定到渲染管线上
	deviceContext->VSSetConstantBuffers(0, 1, &pCBSkyBuffer);
	// 设置SRV
	deviceContext->PSSetShaderResources(0, 1, &pTextureCubeSRV);
	// 绘制
	deviceContext->DrawIndexed(indexCount, 0, 0);
}
```

至此，如果一切ok的话，在`DrawIndexed`方法调用之后，画面就应该显现在最初创建的窗口中了（上述代码只是示意，并不完整）。

***

### 五、天空盒实现的更多细节
以上部分基本就是整个绘制的流程了，总结而言，就是先初始化设备环境，然后创建渲染所需资源，再然后就是绑定到渲染管线上，最后调用`Draw`方法即可绘制了。
想要实现一个完整的天空盒除了上述部分，还有其余的一些操作辅助，包括鼠标键盘事件的捕获和响应，摄像机类的实现以及立方体映射等。关于鼠标键盘以及摄像机类的实现，相关的资料教程很多，就不再赘述。在这小节中，主要叙述一下，我们用HLSL语言编写的着色器到底是如何与C++代码共同工作的（只因我自己曾纠结此处好久）。
当然，我所说的肯定不会是CPU和GPU如何通信之类，仅仅只是最浅层的配置而已，实践起来也很简单。

在本文天空盒绘制中，抛开对三角面片着色等不说，将绘制的天空变换投影到窗口上，这部分就需要顶点着色器来参与完成。至于代码，就以下定义在`Sky_VS.hlsl`文件中的短短几行。
```cpp
VertexPosHL Sky_VS(VertexPos vIn)
{
    VertexPosHL vOut;
    
	// 深度设置为1，保证在无穷远处
    float4 posH = mul(float4(vIn.PosL, 1.0f), g_WorldViewProj);
    vOut.PosH = posH.xyww;
    vOut.PosL = vIn.PosL;
    return vOut;
}
```
其中`VertexPos `就对应着我们最初的顶点数据类型，该结构体类型仍需要在HLSL代码中进行定义。当我们调用`SetVertexBuffers`后，我们在顶点缓冲区中的顶点数据就会流入至上述着色器的形参`VertexPos vIn`中。
同理，`VertexPosHL`就代表着顶点着色器的输出，像素着色器的输入。
最后，观察投影矩阵`g_WorldViewProj`是在另外一个结构体中定义的，这个结构体后的`register(b0)`表示它绑定到了0号端口，在我们的C++代码中，我们只需要在调用`SetVSConstantBuffers`，也将同等语义对应的缓冲区绑定到0号端口即可。
```cpp
// Sky.hlsli
cbuffer SkyBufferStruct : register(b0)
{
    matrix g_WorldViewProj;
}

struct VertexPos
{
    float3 PosL : POSITION;
};
```
```cpp
// D3DSky.h
struct SkyBufferStruct
{
	DirectX::XMMATRIX worldViewProj;
};

struct VertexPos
{
	DirectX::XMFLOAT3 pos;
	static const D3D11_INPUT_ELEMENT_DESC inputLayout[1];
};
```

对于常量缓冲区而言，其所需要的操作都大致如下：
* 创建缓冲区
* 设置缓冲区
* 利用变量更新数据
```cpp
struct SkyBufferStruct
{
	DirectX::XMMATRIX worldViewProj;
};
ComPtr<ID3D11Buffer> pCBSkyBuffer;
SkyBufferStruct varCBSky;

d3dHelper->CreateConstBuffer(sizeof(SkyBufferStruct), pCBSkyBuffer.GetAddressOf());	// 创建缓冲区
d3dHelper->SetVSConstantBuffers(0, 1, pCBSkyBuffer.GetAddressOf());					// 绑定缓冲区到0号端口
// 修改varCBSky的值
d3dHelper->UpdateConstBuffer(varCBSky, pCBSkyBuffer.Get());							// 更新常量缓冲区
```
通过在程序中不断更新常量缓冲区的值，我们的程序也就会展现出期望的效果。例如本文中随着摄像头移动，天空地面的全貌也能得以欣赏。

最后，该天空盒的代码可在[链接](https://download.csdn.net/download/wz2671/12194516)中进行下载。
