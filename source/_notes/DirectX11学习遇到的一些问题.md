---
title: DirectX11学习遇到的一些问题
date: 2020-02-24 17:03:08
tags: 
---

[原文链接](https://blog.csdn.net/wz2671/article/details/104329636)
<!--more -->


###  关于相机类实现
相机的核心其实就是观察矩阵(View Matrix)和投影矩阵(Project Matrix)，第一人称和第三人称相机的本质是根据操作更新上述两个矩阵。
这两个矩阵需要绑定到常量缓冲区，随着鼠键操作不断更新。
投影矩阵的更新需要用到视锥体，一般在窗口大小变化时才需要更新。

```cpp
class WZCamera
{
public:
	WZCamera();
	virtual ~WZCamera() = 0;

	// 获取摄像机位置
	DirectX::XMVECTOR GetPositionXM() const { return XMLoadFloat3(&position); }
	DirectX::XMFLOAT3 GetPosition() const { return position; }

	// 获取矩阵
	DirectX::XMMATRIX GetViewXM() const { return XMLoadFloat4x4(&viewMatrix); }
	DirectX::XMMATRIX GetProjXM() const { return XMLoadFloat4x4(&projMatrix); }
	DirectX::XMMATRIX GetViewProjXM() const { return XMLoadFloat4x4(&viewMatrix) * XMLoadFloat4x4(&projMatrix); }

	// 设置视锥体,计算投影矩阵
	void SetFrustum(float fovY, float aspect, float nearZ, float farZ);

	// 更新观察矩阵
	virtual void UpdateViewMatrix() = 0;


protected:
	// 摄像机的观察空间坐标系对应在世界坐标系中的表示
	DirectX::XMFLOAT3 position;	// 摄像机位置

	// 视锥体
	struct frustum
	{
		float nearZ;
		float farZ;
		float aspect;
		float fovY;
		float nearWindowHeight;
		float farWindowHeight;
	} theFrustum;


	DirectX::XMFLOAT4X4 viewMatrix;		// 观察矩阵
	DirectX::XMFLOAT4X4 projMatrix;		// 投影矩阵
};

class FirstPersonCamera : public WZCamera
{
public:
	FirstPersonCamera();
	~FirstPersonCamera() override;
	// 初始化摄像机
	void Init(const DirectX::XMFLOAT3& pos, const DirectX::XMFLOAT3& target, const DirectX::XMFLOAT3& yaxis);
	void Init(const DirectX::XMFLOAT3& pos);
	// 设置摄像机位置
	void SetPosition(float x, float y, float z) {SetPosition(DirectX::XMFLOAT3(x, y, z)); }
	void SetPosition(const DirectX::XMFLOAT3& v) { position = v; }
	// 设置摄像机的朝向， to表示相机的z轴方向
	void LookTo(const DirectX::XMFLOAT3& pos, const DirectX::XMFLOAT3& to, const DirectX::XMFLOAT3& up);

	// 上下观察
	void LookUpDown(float rad);
	// 左右观察
	void LookLeftRight(float rad);

	// 更新观察矩阵
	void UpdateViewMatrix() override;

private:
	void XM_CALLCONV UpdateAxis(DirectX::FXMVECTOR pos, DirectX::FXMVECTOR to, DirectX::FXMVECTOR up);
	void UpdateAxis(const DirectX::XMFLOAT3& pos, const DirectX::XMFLOAT3& to, const DirectX::XMFLOAT3& up);

private:
	DirectX::XMFLOAT3 Xaxis;	// 摄像机坐标系的x轴，方向向量
	DirectX::XMFLOAT3 Yaxis;	// 朝上的向量，y轴
	DirectX::XMFLOAT3 Zaxis;	// 镜头方向的单位向量，z轴
};

class ThirdPersonCamera : public WZCamera
{
public:
	ThirdPersonCamera();
	~ThirdPersonCamera() override;

	void Init(const DirectX::XMFLOAT3 & target, float);	// 初始化第三人称相机
	void Init(DirectX::XMFLOAT3 & target, float dist, float minDist, float maxDist, float phi, float theta);

	// 获取当前跟踪物体的位置
	DirectX::XMFLOAT3 GetTargetPosition() const { return target; }
	// 绕物体上下旋转(以物体为圆心，x=0的平面旋转，phi \in [pi/6, pi/2])
	void UpdateX(float rad);
	// 绕物体水平旋转
	void UpdateY(float rad);
	// 拉近物体
	void Approach(float dist);
	// 设置并绑定待跟踪物体的位置
	void SetTarget(const DirectX::XMFLOAT3& target);
	
	void UpdatePosition();
	// 更新观察矩阵
	void UpdateViewMatrix() override;

private:
	DirectX::XMFLOAT3 target;
	float distance;
	// 最小允许距离，最大允许距离
	float minDist, maxDist;
	// 以世界坐标系为基准，当前的旋转角度
	float theta;		// 左右视野角度
	float phi;			// 上下视野角度
};

```
- 对于第一人称相机，确定了相机的位置（坐标）后，再根据视角方向绕该点旋转（一般是沿x和y轴旋转）。
- 对于第三人称相机，确定的目标点的位置之后，再根据与目标点的距离d和夹角，确定相机所在的位置（一般相机所在位置在一个半径为d的球面上）。

***

 ### 关于顶点数据封装
 我想为常用的几何体写一个生成顶点和索引数组的函数，但是在绘图过程中并没有显示。

```cpp
class D3DGeometry
{
private:
	std::vector<VertexLayout> vertexVector;	// 顶点数组
	std::vector<UINT> indexVector;		// 索引数组

public:
	// 返回向量，主要问题出在这里
	std::vector<VertexLayout> GetVertexVector() const { return this->vertexVector; }		
	std::vector<UINT> GetIndexVector() const { return this->indexVector; }
	
	// 向量大小
	UINT VertexVectorSize() const { return static_cast<UINT>(this->vertexVector.size()); }
	UINT IndexVectorSize() const { return static_cast<UINT>(this->indexVector.size()); }

	D3DGeometry& CreatePlane(float length, float width, float texU, float texV);		// 创建平面
	D3DGeometry& CreateCurve();		// 创建曲面
};
};
```

 经排查，主要是返回向量的问题，最终改成了公共类型，可直接访问。
```cpp
class D3DGeometry
{
public:
	std::vector<VertexLayout> vertexVector;	// 顶点数组
	std::vector<UINT> indexVector;		// 索引数组

public:
	D3DGeometry& CreatePlane(float length, float width, float texU, float texV);		// 创建平面
	D3DGeometry& CreateCurve();		// 创建曲面
};
```
出现这种问题的原因个人觉得是返回的值是拷贝出的临时变量，在绑定到缓冲区时生命周期并不是全局的。
 ***
 
### 常量结构体和HLSL结构体对应
写的时候一定对应好，一时疏忽会浪费好多时间，连报错都没有。。。

```cpp
struct CBCameraMatrix
{
	DirectX::XMMATRIX view;
	DirectX::XMFLOAT4 eyePos;
	DirectX::XMMATRIX proj;
};

cbuffer CBCameraMatrix : register(b1)
{
	matrix g_View;
	matrix g_Proj;
	float3 g_EyePosW;
}
```
### 索引的顺序
原以为利用索引就可以随意绘制三角形，后续发现还是需要遵从一定的规则，下段实现就无法从一个方向看到完整的矩阵。
```cpp
D3DGeometry& D3DGeometry::CreatePlane(float length, float width, float texU, float texV)
{
	vertexVector.push_back(VertexLayout(XMFLOAT3(-length / 2, 0.0f, -width / 2), XMFLOAT3(0.0f, 1.0f, 0.0f), XMFLOAT2(0.0f, texV)));
	vertexVector.push_back(VertexLayout(XMFLOAT3(-length / 2, 0.0f, width / 2), XMFLOAT3(0.0f, 1.0f, 0.0f), XMFLOAT2(0.0f, 0.0f)));
	vertexVector.push_back(VertexLayout(XMFLOAT3(length / 2, 0.0f, width / 2), XMFLOAT3(0.0f, 1.0f, 0.0f), XMFLOAT2(texU, 0.0f)));
	vertexVector.push_back(VertexLayout(XMFLOAT3(length / 2, 0.0f, -width / 2), XMFLOAT3(0.0f, 1.0f, 0.0f), XMFLOAT2(texU, texV)));

	indexVector = { 0, 1, 2, 2, 3, 0 };	
	return *this;
}
```
当时我采用了`D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP`图元拓扑来绘制，那么绘制时，需要顺时针，逆时针交替，也就是改为`indexVector = {0, 1, 2, 0, 3, 2}`即可正确绘制。
但如若设置为`D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST`那么就都按照顺时针绘制（如果按逆时针绘制，那么绘制出来的图像在该面的另一面）。

***

### 变换矩阵顺序
由于物体在世界中位置并不是一成不变，需要经过多种变换，不同的顺序可能导致不是期望的结果，根据《Unity Shader 入门精要》书中第四章所述，变化的顺序应为：**先进行缩放变换，在进行旋转变换，最后进行平移变换。** 对于旋转变换，**先对z轴旋转，再y轴，最后x轴**。

在计算一个物体A的世界矩阵时，若它依附于其他物体B，那么应当计算出该物体A变换到物体B的相对坐标系的变换矩阵M，再与B的世界矩阵相乘，得出A自身的世界矩阵。这样才能保证得到正确的顺序。

***

### 纹理贴图
为了给模型穿上美美的新衣，必然是要进行贴图的。
一般创建纹理可以使用[DDSTextureLoader](https://github.com/Microsoft/DirectXTex/tree/master/DDSTextureLoader)来读取dds纹理（至于[WICTextureLoader](https://github.com/Microsoft/DirectXTex/tree/master/WICTextureLoader)，在我使用过程中百般尝试也没搞定它）。

同时，dds纹理也不是能100%能贴上去的，比较靠谱的方法是用**DirectX Texture Tool**（一般在目录`D:\Microsoft DirectX SDK(June 2010)\Utilities\Bin\x86`中）对纹理进行处理修改格式后（例如改成`X8R8G8B8`），就可以使用了。

***

### 天空球实现
在实现天空球时，一般采用立方体映射技术，这一实现过程在许多教程中采用了与绘制场景中物体不同的渲染流程。

所以需要注意的是要单独为该渲染所需资源重新创建缓冲区，视图等，并在绘制该天空球之前更换绑定相应的寄存器，设置着色器等。
