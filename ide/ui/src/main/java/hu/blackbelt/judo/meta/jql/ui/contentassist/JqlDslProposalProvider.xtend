/*
 * generated by Xtext 2.18.0
 */
package hu.blackbelt.judo.meta.jql.ui.contentassist

import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.eclipse.xtext.ui.editor.XtextSourceViewer
import hu.blackbelt.judo.meta.esm.namespace.NamedElement
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.Keyword

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class JqlDslProposalProvider extends AbstractJqlDslProposalProvider {

	override complete_QualifiedName(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		acceptor.accept(createCompletionProposal("self", context));
	}

	override complete_Feature(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		var current = context.currentElem
		current.eContainer.eContainer.eContents.forEach[
			acceptor.accept(createCompletionProposal((it as NamedElement).name, context))
		]		
	}
	
	override complete_Function(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.complete_Function(model, ruleCall, context, acceptor)
	}

	def currentElem(ContentAssistContext context) {
		val viewer = context.viewer as XtextSourceViewer
		return viewer.getData("self") as EObject;	
	}
	
	override completeRuleCall(RuleCall ruleCall, ContentAssistContext contentAssistContext, ICompletionProposalAcceptor acceptor) {
		super.completeRuleCall(ruleCall, contentAssistContext, acceptor)
	}
	
	override completeAssignment(Assignment assignment, ContentAssistContext contentAssistContext, ICompletionProposalAcceptor acceptor) {
	}
	
	override completeKeyword(Keyword keyword, ContentAssistContext contentAssistContext, ICompletionProposalAcceptor acceptor) {
	}
	
	
}
