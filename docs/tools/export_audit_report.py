"""Export the saved audit and latest live-test evidence to a shareable PDF."""
from pathlib import Path
import html,json,re
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,PageBreak
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader

ROOT=Path(__file__).resolve().parents[2]
e=json.loads((ROOT/'docs/validation/backend-retest-latest.json').read_text(encoding='utf-8'))
source=(ROOT/'docs/AUDITORIA_PRE_APRESENTACAO.md').read_text(encoding='utf-8')
source='\n'.join(source.splitlines()[1:])
first_section=source.find('## Etapa A')
if first_section>=0:source=source[first_section:]
start=source.find('\n## Reteste com backend ligado')
end=source.find('\n## Retestes após instalação')
if start>=0 and end>start:source=source[:start]+source[end:]
pdfmetrics.registerFont(TTFont('AuditArial','C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('AuditArialBold','C:/Windows/Fonts/arialbd.ttf'))
pdfmetrics.registerFontFamily('AuditArial',normal='AuditArial',bold='AuditArialBold',italic='AuditArial',boldItalic='AuditArialBold')
purple=colors.HexColor('#6537A9');ink=colors.HexColor('#252936')
styles={
 'body':ParagraphStyle('body',fontName='AuditArial',fontSize=9.3,leading=14,textColor=ink,spaceAfter=6,splitLongWords=True),
 'title':ParagraphStyle('title',fontName='AuditArialBold',fontSize=26,leading=30,textColor=purple,spaceAfter=14),
 'h1':ParagraphStyle('h1',fontName='AuditArialBold',fontSize=16,leading=20,textColor=purple,spaceBefore=14,spaceAfter=9,keepWithNext=True),
 'h2':ParagraphStyle('h2',fontName='AuditArialBold',fontSize=11,leading=15,textColor=ink,spaceBefore=12,spaceAfter=6,keepWithNext=True),
 'table':ParagraphStyle('table',fontName='AuditArial',fontSize=8,leading=11,splitLongWords=True),
 'code':ParagraphStyle('code',fontName='AuditArial',fontSize=8,leading=12,backColor=colors.HexColor('#F1EDF7'),borderPadding=7,spaceAfter=10),
}
def norm(s):
 return s.replace('\u2014','-').replace('\u2013','-').replace('\u2011','-').replace('\u2192',' -> ').replace('\u2265','>=').replace('\u2264','<=')
def markup(s):
 s=html.escape(norm(str(s)))
 s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',lambda m:'<link href="'+m.group(2)+'" color="#6537A9">'+m.group(1)+'</link>' if m.group(2).startswith('http') else m.group(1),s)
 s=re.sub(r'`([^`]+)`',r'<font color="#58318B">\1</font>',s)
 return re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',s)
story=[]
def para(s,kind='body'):story.append(Paragraph(markup(s),styles[kind]))
def table(rows):
 widths=[150,341] if len(rows[0])==2 else ([214,85,192] if rows[0][0].strip()=='Job' else [55,285,151])
 t=Table([[Paragraph(markup(c.strip()),styles['table']) for c in row] for row in rows],colWidths=widths,repeatRows=1,hAlign='LEFT')
 t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#EAE1F5')),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F8F7FA')]),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6),('LINEBELOW',(0,0),(-1,0),.7,purple),('LINEBELOW',(0,1),(-1,-1),.3,colors.HexColor('#E1DEE7'))]))
 story.extend([t,Spacer(1,8)])
passed=e.get('passed',False)
verdict=('O fluxo integrado de geração foi aprovado. A reprodução nativa e o ensaio com leitor de tela ainda exigem validação na máquina da apresentação.' if passed else 'O fluxo integrado não foi aprovado nesta execução. A causa atual retornada pelo backend está registrada abaixo; o aplicativo tratou a falha sem ficar carregando.')
summary='# See2Sound - Relatório consolidado\n\nAtualização: 24/10/2026\n\n'+verdict+'\n\nJob atual: '+e['job_id']+'\n\nEstados: '+' -> '.join(e['states'])+'\n\nTempo: '+str(e['elapsed_seconds'])+' segundos.\n\n'
summary+=('WAV: '+str(e.get('wav_bytes'))+' bytes; descrições inseridas: '+str(e.get('descriptions_inserted'))+'; biblioteca restaurada: '+str(e.get('library_restored'))+'.\n\n' if passed else 'Causa: '+str(e.get('failure_cause','Consultar evidência JSON.'))+'\n\n')
para('See2Sound','title');para('Auditoria técnica e validação pré-apresentação','h1');para('Relatório consolidado | Atualização: 24/10/2026');para(verdict)
table([['Verificação','Resultado mais recente'],['Análise estática','Aprovada: flutter analyze --no-pub.'],['Suíte isolada','60 testes aprovados; 3 testes reais optativos ignorados.'],['Saúde/404 e falha existente','2 testes de HTTP real aprovados.'],['Geração ponta a ponta','Aprovada' if passed else 'Reprovada nesta execução.'],['Build Windows','Aprovado.' if e.get('windows_build')=='passed' else 'Bloqueado: suporte a links simbólicos/Modo de Desenvolvedor.'],['Reprodução e leitor de tela','Pendentes de ensaio no aplicativo nativo.']])
para('Evidência da execução atual','h2');para('Job: '+e['job_id']);para('Estados: '+' -> '.join(e['states']));para('Tempo observado: '+str(e['elapsed_seconds'])+' segundos. Amostra real: video_teste.mp4; opções padrão de processamento mantidas.')
if passed:para('WAV: '+str(e.get('wav_bytes'))+' bytes. Descrições inseridas: '+str(e.get('descriptions_inserted'))+'. Biblioteca restaurada: '+str(e.get('library_restored'))+'.')
else:para('Causa retornada pelo backend: '+str(e.get('failure_cause')))
para('Leitura deste relatório','h2');para('Este resumo prevalece sobre as observações históricas do anexo. O teste integrado usa HTTP, upload e pipeline reais. Apenas as preferências locais do teste são isoladas para preservar a biblioteca do usuário. Os testes de geometria não substituem a reprodução nativa.')
story.append(PageBreak());para('Auditoria completa e histórico de validação','title')
lines=source.splitlines();i=0
while i<len(lines):
 line=lines[i].strip()
 if not line:i+=1;continue
 if line.startswith('```'):
  i+=1;code=[]
  while i<len(lines) and not lines[i].startswith('```'):code.append(lines[i]);i+=1
  story.append(Paragraph('<br/>'.join(html.escape(norm(x)) or ' ' for x in code),styles['code']));i+=1;continue
 if line.startswith('|'):
  rows=[]
  while i<len(lines) and lines[i].strip().startswith('|'):
   raw=lines[i].strip()
   if not re.fullmatch(r'[| :\-]+',raw):rows.append(raw.strip('|').split('|'))
   i+=1
  if rows:table(rows)
  continue
 if line.startswith('## '):
  if line.startswith('## Etapa B'):story.append(PageBreak())
  para(line[3:],'h1')
 elif line.startswith('### '):para(line[4:],'h2')
 elif line.startswith('- '):story.append(Paragraph(markup(line[2:]),styles['body'],bulletText='-'))
 else:
  parts=[line]
  while i+1<len(lines) and lines[i+1].strip() and not re.match(r'^(#|\||```|- |\d+\. )',lines[i+1].strip()):i+=1;parts.append(lines[i].strip())
  para(' '.join(parts))
 i+=1
class AuditDoc(SimpleDocTemplate):
 def afterFlowable(self,f):
  if isinstance(f,Paragraph) and f.style.name in ('h1','title'):
   key='section-'+str(self.seq.nextf('bookmark'));self.canv.bookmarkPage(key);self.canv.addOutlineEntry(f.getPlainText(),key,level=0)
def decorate(c,doc):
 w,h=A4;c.setStrokeColor(purple);c.setLineWidth(2);c.line(52,h-37,w-52,h-37);c.setFont('AuditArialBold',9);c.setFillColor(purple);c.drawString(52,h-27,'See2Sound | Auditoria técnica');c.setFont('AuditArial',8);c.setFillColor(colors.HexColor('#657084'));c.drawString(52,27,'Pré-apresentação | 24/10/2026');c.drawRightString(w-52,27,str(doc.page))
out=ROOT/'output/pdf';out.mkdir(parents=True,exist_ok=True)
pdf=out/'See2Sound_Relatorio_Auditoria.pdf'
AuditDoc(str(pdf),pagesize=A4,leftMargin=52,rightMargin=52,topMargin=55,bottomMargin=48,title='See2Sound - Relatório de Auditoria Técnica',author='See2Sound - Auditoria técnica').build(story,onFirstPage=decorate,onLaterPages=decorate)
(out/'See2Sound_Relatorio_Auditoria.md').write_text(summary+source,encoding='utf-8')
r=PdfReader(str(pdf));text='\n'.join(p.extract_text() or '' for p in r.pages)
assert e['job_id'] in text and '16:9' in text and len(text)>12000
print(json.dumps({'pdf':str(pdf),'pages':len(r.pages),'bytes':pdf.stat().st_size},ensure_ascii=False))
