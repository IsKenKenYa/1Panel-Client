import { i18n } from '@kit.LocalizationKit';

// 电话号码实时格式化示例(TYPING格式)

// 示例1: 基本实时格式化
function typingFormatBasicExample(): void {
  console.log('=== 基本实时格式化示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
  const phoneNumber: string = '0755453';
  let currentInput: string = '';
  
  console.log('模拟用户逐字符输入:');
  for (let i = 0; i < phoneNumber.length; i++) {
    currentInput += phoneNumber.charAt(i);
    const formattedNumber: string = formatter.format(currentInput);
    console.log(`输入字符: ${phoneNumber.charAt(i)}, 当前输入: ${currentInput}, 格式化结果: ${formattedNumber}`);
  }
  
  console.log(`最终格式化结果: ${formatter.format(currentInput)}`); // 输出: 0755 453
}

// 示例2: 实时格式化界面组件模拟
function typingFormatUIExample(): void {
  console.log('=== 实时格式化界面组件模拟 ===');
  
  // 模拟界面输入状态
  interface InputState {
    rawInput: string;      // 用户原始输入
    displayText: string;    // 格式化后显示文本
    cursorPosition: number; // 光标位置
  }
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
  let state: InputState = {
    rawInput: '',
    displayText: '',
    cursorPosition: 0
  };
  
  // 模拟用户输入函数
  function simulateUserInput(newChar: string): void {
    state.rawInput += newChar;
    state.displayText = formatter.format(state.rawInput);
    state.cursorPosition = state.displayText.length;
    
    console.log(`用户输入: ${newChar}`);
    console.log(`原始输入: ${state.rawInput}`);
    console.log(`显示文本: ${state.displayText}`);
    console.log(`光标位置: ${state.cursorPosition}`);
    console.log('---');
  }
  
  // 模拟用户输入过程
  const inputSequence: string = '13812345678';
  console.log('开始模拟用户输入序列: ' + inputSequence);
  
  for (const char of inputSequence) {
    simulateUserInput(char);
  }
  
  console.log(`最终显示: ${state.displayText}`);
}

// 示例3: 实时格式化与退格处理
function typingFormatWithDeleteExample(): void {
  console.log('=== 实时格式化与退格处理示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
  let currentInput: string = '';
  
  // 模拟输入
  const inputChars: string[] = ['1', '3', '8', '1', '2', '3', '4'];
  
  console.log('输入阶段:');
  for (const char of inputChars) {
    currentInput += char;
    const formatted: string = formatter.format(currentInput);
    console.log(`输入 ${char}: ${currentInput} -> ${formatted}`);
  }
  
  // 模拟退格删除
  console.log('\n删除阶段:');
  for (let i = 0; i < 3; i++) {
    currentInput = currentInput.slice(0, -1);
    const formatted: string = formatter.format(currentInput);
    console.log(`退格删除: ${currentInput} -> ${formatted}`);
  }
  
  // 继续输入
  console.log('\n继续输入:');
  const additionalChars: string[] = ['5', '6', '7', '8'];
  for (const char of additionalChars) {
    currentInput += char;
    const formatted: string = formatter.format(currentInput);
    console.log(`输入 ${char}: ${currentInput} -> ${formatted}`);
  }
}

// 示例4: 多国家实时格式化
function typingFormatMultiCountryExample(): void {
  console.log('=== 多国家实时格式化示例 ===');
  
  // 中国号码实时格式化
  const cnFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
  const cnNumber: string = '1381234567';
  let cnInput: string = '';
  
  console.log('中国号码实时格式化:');
  for (let i = 0; i < cnNumber.length; i++) {
    cnInput += cnNumber.charAt(i);
    console.log(`${cnInput} -> ${cnFormatter.format(cnInput)}`);
  }
  
  // 美国号码实时格式化
  const usFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('US', { type: 'TYPING' });
  const usNumber: string = '4155552671';
  let usInput: string = '';
  
  console.log('\n美国号码实时格式化:');
  for (let i = 0; i < usNumber.length; i++) {
    usInput += usNumber.charAt(i);
    console.log(`${usInput} -> ${usFormatter.format(usInput)}`);
  }
}

// 示例5: 实时格式化状态管理
function typingFormatStateManagement(): void {
  console.log('=== 实时格式化状态管理示例 ===');
  
  // 状态管理器
  class PhoneNumberInputManager {
    private formatter: i18n.PhoneNumberFormat;
    private rawInput: string = '';
    private displayText: string = '';
    
    constructor(country: string) {
      this.formatter = new i18n.PhoneNumberFormat(country, { type: 'TYPING' });
    }
    
    // 添加字符
    addCharacter(char: string): void {
      this.rawInput += char;
      this.updateDisplay();
    }
    
    // 删除字符
    removeCharacter(): void {
      if (this.rawInput.length > 0) {
        this.rawInput = this.rawInput.slice(0, -1);
        this.updateDisplay();
      }
    }
    
    // 清空输入
    clearInput(): void {
      this.rawInput = '';
      this.displayText = '';
    }
    
    // 更新显示
    private updateDisplay(): void {
      this.displayText = this.formatter.format(this.rawInput);
    }
    
    // 获取当前状态
    getState(): { raw: string; display: string } {
      return {
        raw: this.rawInput,
        display: this.displayText
      };
    }
  }
  
  // 使用状态管理器
  const manager: PhoneNumberInputManager = new PhoneNumberInputManager('CN');
  
  console.log('初始状态:', manager.getState());
  
  manager.addCharacter('1');
  console.log('输入1后:', manager.getState());
  
  manager.addCharacter('3');
  console.log('输入3后:', manager.getState());
  
  manager.addCharacter('8');
  console.log('输入8后:', manager.getState());
  
  manager.removeCharacter();
  console.log('退格后:', manager.getState());
  
  manager.clearInput();
  console.log('清空后:', manager.getState());
}

// 执行所有示例
typingFormatBasicExample();
typingFormatUIExample();
typingFormatWithDeleteExample();
typingFormatMultiCountryExample();
typingFormatStateManagement();