<template>
  <div class="resume-container">
    <!-- 加载状态提示 -->
    <div v-if="loading" class="loading-text">
      {{ loadingText }}
    </div>

    <!-- 顶部导航栏 -->
    <div class="nav-bar">
      <el-button @click="goBack">返回上一页</el-button>
      <div class="nav-title">简历编辑器</div>
      <div class="nav-actions">
        <el-button type="success" @click="updateResume" :loading="updating">更新简历</el-button>
        <el-button type="primary" @click="exportResume('pdf')">导出 PDF</el-button>
        <el-button type="primary" @click="exportResume('word')">导出 Word</el-button>
      </div>
    </div>

    <div class="resume-container">
      <!-- 左侧：模块选择 -->
      <div class="sidebar" :class="{ loading }">
        <div class="module-list">
          <h3>模块选择</h3>
          <el-checkbox-group v-model="selectedModules">
            <el-checkbox label="基本信息" />
            <el-checkbox label="求职意向" />
            <el-checkbox label="教育经历" />
            <el-checkbox label="专业技能" />
            <el-checkbox label="工作经历" />
            <el-checkbox label="项目经历" />
            <el-checkbox label="荣誉奖项" />
          </el-checkbox-group>
        </div>
      </div>

      <!-- 中间：信息填写 -->
      <div class="form-container" :class="{ loading }">
        <!-- 基本信息 -->
        <h3 v-if="selectedModules.includes('基本信息')">基本信息</h3>
        <el-form v-if="selectedModules.includes('基本信息')" label-width="100px">
          <el-form-item label="姓名">
            <el-input v-model="resume.name" placeholder="请输入姓名" />
          </el-form-item>
          <el-form-item label="电话">
            <el-input v-model="resume.phone" placeholder="请输入电话" />
          </el-form-item>
          <el-form-item label="邮箱">
            <el-input v-model="resume.email" placeholder="请输入邮箱" />
          </el-form-item>

          <!-- 用户头像上传 -->
          <el-form-item label="头像">
            <el-upload
                class="avatar-uploader"
                action=""
                :show-file-list="false"
                :before-upload="handleAvatarUpload"
            >
              <img v-if="resume.avatar" :src="resume.avatar" class="avatar" />
              <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
            </el-upload>
          </el-form-item>
        </el-form>

        <!-- 求职意向 -->
        <h3 v-if="selectedModules.includes('求职意向')">求职意向</h3>
        <el-form v-if="selectedModules.includes('求职意向')" label-width="100px">
          <el-form-item label="当前状态">
            <el-select v-model="resume.jobStatus" placeholder="请选择当前状态">
              <el-option label="在职" value="在职" />
              <el-option label="离职" value="离职" />
              <el-option label="应届生" value="应届生" />
            </el-select>
          </el-form-item>
          <el-form-item label="职位名称">
            <el-input v-model="resume.jobTitle" placeholder="请输入期望职位" />
          </el-form-item>
          <el-form-item label="期望薪资">
            <el-input v-model="resume.salaryExpectation" placeholder="请输入期望薪资" />
          </el-form-item>
        </el-form>

        <!-- 教育经历 -->
        <h3 v-if="selectedModules.includes('教育经历')">教育经历</h3>
        <el-form v-if="selectedModules.includes('教育经历')" label-width="100px">
          <el-form-item label="学校">
            <el-input v-model="resume.education.school" placeholder="请输入学校" />
          </el-form-item>
          <el-form-item label="专业">
            <el-input v-model="resume.education.major" placeholder="请输入专业" />
          </el-form-item>
          <el-form-item label="学历">
            <el-select v-model="resume.education.degree" placeholder="请选择学历">
              <el-option label="本科" value="本科"></el-option>
              <el-option label="硕士" value="硕士"></el-option>
              <el-option label="博士" value="博士"></el-option>
            </el-select>
          </el-form-item>
          <el-form-item label="在读时间">
            <el-date-picker v-model="resume.education.studyPeriod" type="daterange" start-placeholder="开始时间" end-placeholder="结束时间"/>
          </el-form-item>
        </el-form>

        <!-- 专业技能 -->
        <h3 v-if="selectedModules.includes('专业技能')">专业技能</h3>
        <el-form v-if="selectedModules.includes('专业技能')" label-width="100px">
          <el-form-item label="技能描述">
            <el-input v-model="resume.profession.skill" type="textarea" placeholder="请输入专业技能" />
          </el-form-item>
        </el-form>

        <!-- 工作经历 -->
        <h3 v-if="selectedModules.includes('工作经历')">工作经历</h3>
        <el-form v-if="selectedModules.includes('工作经历')" label-width="100px">
          <el-form-item label="公司名称">
            <el-input v-model="resume.work.company" placeholder="请输入公司名称" />
          </el-form-item>
          <el-form-item label="部门">
            <el-input v-model="resume.work.department" placeholder="请输入部门" />
          </el-form-item>
          <el-form-item label="职位">
            <el-input v-model="resume.work.position" placeholder="请输入职位" />
          </el-form-item>
          <el-form-item label="在职时间">
            <el-date-picker v-model="resume.work.period" type="daterange" start-placeholder="开始时间" end-placeholder="结束时间"/>
          </el-form-item>
          <el-form-item label="工作内容">
            <el-input v-model="resume.work.details" type="textarea" placeholder="请输入工作内容" />
          </el-form-item>
        </el-form>

        <!-- 项目经历 -->
        <h3 v-if="selectedModules.includes('项目经历')">项目经历</h3>
        <el-form v-if="selectedModules.includes('项目经历')" label-width="100px">
          <el-form-item label="项目名称">
            <el-input v-model="resume.project.name" placeholder="请输入项目名称" />
          </el-form-item>
          <el-form-item label="项目时间">
            <el-date-picker v-model="resume.project.period" type="daterange" start-placeholder="开始时间" end-placeholder="结束时间"/>
          </el-form-item>
          <el-form-item label="项目描述">
            <el-input v-model="resume.project.details" type="textarea" placeholder="请输入项目描述" />
          </el-form-item>
        </el-form>

        <!-- 荣誉奖项 -->
        <h3 v-if="selectedModules.includes('荣誉奖项')">荣誉奖项</h3>
        <el-form v-if="selectedModules.includes('荣誉奖项')" label-width="100px">
          <el-form-item label="奖项名称">
            <el-input v-model="resume.award.details" type="textarea" placeholder="请输入奖项名称" />
          </el-form-item>
        </el-form>
      </div>

      <!-- 右侧：预览简历 -->
      <div class="preview-container" :class="{ loading }">
        <!-- 预览区头部 -->
        <div class="preview-header">
          <!-- 左侧：姓名、电话、邮箱 -->
          <div class="preview-contact">
            <h2>{{ resume.name || '姓名' }}</h2>
            <p>📞 {{ resume.phone || '电话' }}</p>
            <p>✉️ {{ resume.email || '邮箱' }}</p>
          </div>

          <!-- 右侧：头像 -->
          <div class="preview-avatar-container">
            <img v-if="resume.avatar" :src="resume.avatar" class="preview-avatar" />
          </div>
        </div>

        <template v-for="module in selectedModules" :key="module">
          <div v-if="module !== '基本信息'" class="section">
            <h3 class="section-title">{{ module }}</h3>
            <div v-html="getFormattedResumeData(module)"></div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import html2pdf from 'html2pdf.js';
import { Document, Packer, Paragraph, TextRun } from "docx";
import { saveAs } from "file-saver";
import { Plus } from '@element-plus/icons-vue';
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { ElMessage } from 'element-plus';

const selectedModules = ref(['基本信息', '求职意向', '教育经历', '专业技能', '工作经历', '项目经历', '荣誉奖项']);
const resume = ref({
  name: '', 
  phone: '', 
  email: '',
  avatar:'',
  jobStatus: '', 
  jobTitle: '', 
  salaryExpectation: '',
  education: { 
    school: '', 
    major: '', 
    degree: '', 
    studyPeriod: [] 
  },
  profession: {
    skill: ''
  },
  work: { 
    company: '', 
    department: '', 
    position: '', 
    period: [], 
    details: '' 
  },
  project: { 
    name: '', 
    period: [], 
    details: '' 
  },
  award: {
    details: ''
  },
});

const loading = ref(false);
const loadingText = ref('');
const updating = ref(false);

// 返回上一页
const goBack = () => {
  window.history.back();
};

// 获取表单组件
const getFormComponent = (module) => {
  const components = {
    '基本信息': 'BasicInfoForm',
    '求职意向': 'JobIntentForm',
    '教育经历': 'EducationForm',
    '专业技能': 'SkillsForm',
    '工作经历': 'WorkExperienceForm',
    '项目经历': 'ProjectExperienceForm',
    '荣誉奖项': 'AwardsForm',
  };
  return components[module] || 'div';
};

// 头像上传处理
const handleAvatarUpload = (file) => {
  const reader = new FileReader();
  reader.onload = (e) => {
    resume.value.avatar = e.target.result; // 读取文件并转换为 Base64
  };
  reader.readAsDataURL(file);
  return false; // 阻止默认上传行为
};

// 获取格式化的简历数据（使用 HTML）
const getFormattedResumeData = (module) => {
  switch (module) {
      case '基本信息':
        return `
          <p><strong>姓名：</strong>${resume.value.name || '未填写'}</p>
          <p><strong>电话：</strong>${resume.value.phone || '未填写'}</p>
          <p><strong>邮箱：</strong>${resume.value.email || '未填写'}</p>
        `;
    case '求职意向':
      return `
        <p><strong>状态：</strong>${resume.value.jobStatus || '未填写'}</p>
        <p><strong>期望职位：</strong>${resume.value.jobTitle || '未填写'}</p>
        <p><strong>期望薪资：</strong>${resume.value.salaryExpectation || '未填写'}</p>
      `;
    case '教育经历':
      return `
        <p><strong>毕业院校：</strong>${resume.value.education.school || '未填写'}</p>
        <p><strong>专业：</strong>${resume.value.education.major || '未填写'}</p>
        <p><strong>学历：</strong>${resume.value.education.degree || '未填写'}</p>
        <p><strong>在读时间：</strong>${formatDate(resume.value.education.studyPeriod?.[0])} - ${formatDate(resume.value.education.studyPeriod?.[1])}</p>
      `;
    case '工作经历':
      return `
        <p><strong>公司名称：</strong>${resume.value.work.company || '未填写'}</p>
        <p><strong>部门：</strong>${resume.value.work.department || '未填写'}</p>
        <p><strong>职位：</strong>${resume.value.work.position || '未填写'}</p>
        <p><strong>在职时间：</strong>${formatDate(resume.value.work.period?.[0])} - ${formatDate(resume.value.work.period?.[1])}</p>
        <p><strong>工作内容：</strong>${resume.value.work.details || '未填写'}</p>
      `;
    case '项目经历':
      return `
        <p><strong>项目名称：</strong>${resume.value.project.name || '未填写'}</p>
        <p><strong>项目时间：</strong>${formatDate(resume.value.project.period?.[0])} - ${formatDate(resume.value.project.period?.[1])}</p>
        <p><strong>项目描述：</strong>${resume.value.project.details || '未填写'}</p>
      `;
    case '荣誉奖项':
      return `
        <p><strong>奖项名称：</strong>${resume.value.award.details || '未填写'}</p>
      `;
    case '专业技能':
      return `
        <p><strong>专业技能：</strong>${resume.value.profession.skill || '未填写'}</p>
      `;
    default:
      return '<p>暂无数据</p>';
  }
};

const formatDate = (date) => {
  if (!date) return '未知日期';
  const d = new Date(date);
  return isNaN(d) ? '未知日期' : d.toISOString().split('T')[0]; // 只保留 YYYY-MM-DD
};

// 导出功能
const exportResume = (format) => {
  const element = document.querySelector('.preview-container');
  if (format === 'pdf') {
    html2pdf().from(element).save('resume.pdf');
  } else if (format === 'word') {
    const doc = new Document({
      sections: [
        {
          properties: {},
          children: selectedModules.value.map(module => {
            return new Paragraph({
              children: [
                new TextRun({ text: module, bold: true, size: 24 }), // 模块标题
                new TextRun("\n"), // 换行
                new TextRun(getResumeData(module)), // 模块内容
                new TextRun("\n\n") // 额外换行
              ]
            });
          })
        }
      ]
    });

    Packer.toBlob(doc).then(blob => {
      saveAs(blob, "resume.docx");
    });
  }
};

const socket = ref(null);
const resumeForm = ref({
  introduction: '',
  skills: '',
  experience: '',
  education: ''
});
function connectWebSocket() {
  socket.value = new WebSocket("ws://localhost:9090/ws/chat");
  socket.value.onopen = () => {
    console.log("WebSocket connected.");
  };
  socket.value.onmessage = (event) => {
    const data = event.data;
    if (data.startsWith("data:")) {
      const json = data.replace("data:", "").trim();
      if (json && json !== "[DONE]") {
        // 假设响应格式为 JSON 字符串：{ introduction: ..., skills: ..., ... }
        try {
          const parsed = JSON.parse(json);
          Object.assign(resumeForm.value, parsed);
        } catch (e) {
          console.warn("非JSON格式响应:", json);
        }
      }
    } else if (data.startsWith("推荐的职业：")) {
      console.log("职业推荐", data);
    }
  };
  socket.value.onerror = (err) => {
    console.error("WebSocket error:", err);
  };
  socket.value.onclose = () => {
    console.log("WebSocket closed.");
  };
}
function sendResumeInput(resumeInput) {
  if (socket.value && socket.value.readyState === WebSocket.OPEN) {
    loading.value = true;
    socket.value.send(JSON.stringify(resumeInput));
  } else {
    console.warn("WebSocket not ready");
  }
}

// 加载生成的简历数据
const loadGeneratedResume = async () => {
  const savedResumeData = localStorage.getItem('resumeData');
  if (savedResumeData) {
    try {
      loading.value = true;
      loadingText.value = '正在加载简历数据...';

      const parsedData = JSON.parse(savedResumeData);
      
      // 首先加载用户基本信息
      if (parsedData.name) {
        resume.value.name = parsedData.name;
        resume.value.phone = parsedData.phone;
        resume.value.email = parsedData.email;
      }
      
      // 使用动画效果逐步更新数据
      const sections = [
        'jobStatus',
        'jobTitle',
        'salaryExpectation',
        'education',
        'profession',
        'work',
        'project',
        'award'
      ];

      for (let i = 0; i < sections.length; i++) {
        const section = sections[i];
        loadingText.value = `正在加载${getModuleName(section)}...`;
        
        // 合并数据，保留用户已填写的基本信息
        if (typeof parsedData[section] === 'object') {
          resume.value[section] = {
            ...resume.value[section],
            ...parsedData[section]
          };
        } else {
          resume.value[section] = parsedData[section];
        }
        
        // 添加延迟以创建动画效果
        await new Promise(resolve => setTimeout(resolve, 200));
      }

      // 清除localStorage中的数据，避免重复加载
      localStorage.removeItem('resumeData');
      
      ElMessage.success('简历数据加载完成');
    } catch (error) {
      console.error('解析简历数据失败:', error);
      ElMessage.error('加载简历数据失败: ' + error.message);
    } finally {
      loading.value = false;
      loadingText.value = '';
    }
  }
};

// 获取模块名称
const getModuleName = (section) => {
  const moduleNames = {
    jobStatus: '求职状态',
    jobTitle: '期望职位',
    salaryExpectation: '期望薪资',
    education: '教育经历',
    profession: '专业技能',
    work: '工作经历',
    project: '项目经历',
    award: '获奖情况'
  };
  return moduleNames[section] || section;
};

// 加载最新简历数据
const loadLatestResume = async () => {
  const userId = localStorage.getItem('userId');
  if (!userId) {
    ElMessage.warning('请先登录');
    return;
  }

  try {
    loading.value = true;
    loadingText.value = '正在加载最新简历...';

    const response = await fetch(`http://localhost:9090/ai/resume/latest?userId=${userId}`);
    const result = await response.json();

    if (!result.success) {
      throw new Error(result.error || '加载失败');
    }

    // 更新简历数据
    const resumeData = result.content;
    updateResumeData(resumeData);

    ElMessage.success('简历加载完成');
  } catch (error) {
    console.error('加载简历失败:', error);
    ElMessage.error(error.message);
  } finally {
    loading.value = false;
    loadingText.value = '';
  }
};

// 更新简历到数据库
const updateResume = async () => {
  const userId = localStorage.getItem('userId');
  if (!userId) {
    ElMessage.warning('请先登录');
    return;
  }

  try {
    updating.value = true;
    
    const response = await fetch('http://localhost:9090/ai/resume/update', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        userId,
        resumeData: {
          name: resume.value.name,
          phone: resume.value.phone,
          email: resume.value.email,
          jobStatus: resume.value.jobStatus,
          jobTitle: resume.value.jobTitle,
          salaryExpectation: resume.value.salaryExpectation,
          education: resume.value.education,
          profession: resume.value.profession,
          work: resume.value.work,
          project: resume.value.project,
          award: resume.value.award
        }
      })
    });

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(result.error || '更新失败');
    }

    ElMessage.success('简历更新成功');
  } catch (error) {
    console.error('更新简历失败:', error);
    ElMessage.error(error.message);
  } finally {
    updating.value = false;
  }
};

// 更新简历数据
const updateResumeData = (data) => {
  resume.value = {
    name: data.name || '',
    phone: data.phone || '',
    email: data.email || '',
    jobStatus: data.jobStatus || '',
    jobTitle: data.jobTitle || '',
    salaryExpectation: data.salaryExpectation || '',
    education: data.education || { 
      school: '', 
      major: '', 
      degree: '', 
      studyPeriod: [] 
    },
    profession: data.profession || {
      skill: ''
    },
    work: data.work || { 
      company: '', 
      department: '', 
      position: '', 
      period: [], 
      details: '' 
    },
    project: data.project || { 
      name: '', 
      period: [], 
      details: '' 
    },
    award: data.award || {
      details: ''
    }
  };
};

// 在组件挂载时加载数据
onMounted(() => {
  connectWebSocket();
  const savedResumeData = localStorage.getItem('resumeData');
  if (savedResumeData) {
    loadGeneratedResume();
  } else {
    loadLatestResume();
  }
});
onBeforeUnmount(() => {
  socket.value?.close();
});
</script>

<style scoped>
.resume-container {
  display: flex;
  height: 100vh;
  position: relative;
  background: #f0f8ff;
}

.nav-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  background: linear-gradient(135deg, #ffffff 0%, #e6f3ff 80%);
  color: white;
  height: 40px;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
}

.nav-title {
  font-size: 18px;
  font-weight: bold;
}

/* 左侧模块 */
.sidebar {
  width: 200px;
  background: linear-gradient(135deg, #ffffff 0%, #e6f3ff 100%);
  padding: 20px;
  border-right: 2px solid #ddd;
  border-radius: 12px 0 0 12px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);
  margin-right: 2px; /* 分隔线 */
  display: grid;
}

.el-checkbox-group{
  display: grid;
}

/* 中间填写表单 */
.form-container {
  flex: 2;
  background: white;
  padding: 30px;
  border-radius: 0 12px 12px 0;
  overflow-y: auto;
  max-width: 550px;
  max-height: 100vh;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  margin-right: 2px; /* 分隔线 */
  scrollbar-width: thin; /* 滚动条样式 */
  scrollbar-color: #b22323 #599bf1;
}


/* 头像上传样式 */
.avatar-uploader {
  width: 100px;
  height: 100px;
  border: 1px dashed #ccc;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  cursor: pointer;
}

.avatar {
  width: 100%;
  height: 100%;
  border-radius: 50%;
}

/* 右侧预览区域 */
.preview-container {
  flex: 1;
  padding: 30px;
  background: #ffffff;
  box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  max-height: 100vh;
  grid-template-columns: 3fr 2fr; /* 调整左右比例 */
  min-width: 540px;
  border-radius: 12px;
  scrollbar-width: thin; /* 滚动条样式 */
  scrollbar-color: #e0e0e0 #f5f5f5;
}

.preview-contact {
  flex: 1; /* 占据剩余空间 */
  text-align: left;
}

.preview-header {
  display: flex;
  align-items: center; /* 头像顶部对齐 */
  justify-content: space-between; /* 左右分布 */
  padding-bottom: 20px;
  border-bottom: 1px solid #eee;
}

/* 预览区头像 */
.preview-avatar-container {
  flex: 0 0 auto; /* 不伸缩 */
  width: 120px;
  height: 120px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 6px rgba(0, 0, 0, 0.2); /* 阴影美化 */
}

.preview-avatar {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
}


/* 滚动条自定义样式 */
.preview-container::-webkit-scrollbar {
  width: 8px;
}

.preview-container::-webkit-scrollbar-track {
  background: #f5f5f5;
  border-radius: 4px;
}
.preview-container::-webkit-scrollbar-thumb {
  background: #e0e0e0;
  border-radius: 4px;
}

.form-container::-webkit-scrollbar {
  width: 8px;
}

.form-container::-webkit-scrollbar-track {
  background: #f5f5f5;
  border-radius: 4px;
}
.form-container::-webkit-scrollbar-thumb {
  background: #e0e0e0;
  border-radius: 4px;
}


/*预览标题*/
.section-title {
  background-color: #dae2f1;
  color: white;
  padding: 5px 10px;
  border-radius: 5px;
  margin-bottom: 10px;
  border-left: 4px solid #b9cffd;
}

/* 添加过渡效果 */
.form-container, .preview-container {
  position: relative;
}

.form-container::before,
.preview-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
  opacity: 0;
  visibility: hidden;
  transition: all 0.3s ease-in-out;
}

.form-container.loading::before,
.preview-container.loading::before {
  opacity: 1;
  visibility: visible;
}

.loading-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 11;
  color: #409EFF;
  font-size: 16px;
  text-align: center;
  background: rgba(255, 255, 255, 0.9);
  padding: 20px;
  border-radius: 4px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

/* 添加数据更新的过渡效果 */
.el-form-item {
  transition: all 0.3s ease-in-out;
}

.el-form-item.updated {
  animation: highlight 1s ease-in-out;
}

@keyframes highlight {
  0% {
    background-color: rgba(64, 158, 255, 0.1);
  }
  100% {
    background-color: transparent;
  }
}
</style>